
LOG_FILE="/var/log/setup-script.log"
API_PORT = "6443"
MAX_RETRIES = 100

sudo yum install -y awscli

#install private key
aws secretsmanager get-secret-value --secret-id node_rsa_key --query SecretString --output text > /home/ec2-user/.ssh/id_rsa
chmod 400 /home/ec2-user/.ssh/id_rsa

#find control plane IP
retries=0
until [[ "$retries" == MAX_RETRIES ]]; do
  CTLPLANE_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=node_control_plane" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
  if [ -z "$CTLPLANE_IP" ]; then
    echo "failed to find control plane IP. waiting 5 secs and trying again" >> $LOG_FILE
    sleep 5
    count=$((count + 1))
  fi
done

retries=0
until [[ "$retries" == MAX_RETRIES ]]; do
  DATAPLANE_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=node_control_plane" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
  if [ -z "$DATAPLANE_IP" ]; then
    echo "failed to find control plane IP. waiting 5 secs and trying again" >> $LOG_FILE
    sleep 5
    count=$((count + 1))
  fi
done


# check if control plane is ready
count = 0
until [ "$count" == $MAX_RETRIES ]; do
  status = `curl -k -s -o /dev/null -w "%{http_code}" https://${CTLPLANE_IP}:${API_PORT}/readyz || true`
  if $status -eq 200; then
    echo "Control plane is READY! (HTTP 200 received)" >> $LOG_FILE
    break
  fi
  echo "control plane isn't ready. Trying again" >> $LOG_FILE
  count=$((count + 1))
  sleep 5
done

kubeadm_join_cmd=$(ssh -l ec2-user ${CTLPLANE_IP} "kubeadm token create --print-join-command")
echo "kubeadm_join_cmd: ${kubeadm_join_cmd}" >> $LOG_FILE
echo "Running the join command on workder nodes" >> $LOG_FILE

ssh -l ec2-user ${DATAPLANE_IP} "sudo ${kubeadm_join_cmd}" >> $LOG_FILE 2>&1

#install kubectl client
curl -LO "https://dl.k8s.io/release/v1.31.0/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/ && echo "installed kubectl cli" >> $LOG_FILE

#copy config

mkdir /home/ec2-user/.kube
scp ec2-user@${CTLPLANE_IP}:/home/ec2-user/.kube/config /home/ec2-user/.kube/config 2>&1 >> $LOG_FILE 

