#!/bin/bash

fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

LOG_FILE="/tmp/setup.log"
MAX_RETRIES=60

cat << EOF >> /home/ec2-user/.ssh/config
Host *
  StrictHostKeyChecking no
EOF

dnf install -y git awscli python-pip >> $LOG_FILE
aws secretsmanager get-secret-value --secret-id node_rsa_key --query SecretString --output text > /home/ec2-user/.ssh/id_rsa 2> $LOG_FILE
chown ec2-user /home/ec2-user/.ssh/id_rsa
chmod 400 /home/ec2-user/.ssh/id_rsa

mkdir /var/log/ansible
chown ec2-user.ec2-user /var/log/ansible
sudo -u ec2-user pip3 install boto3 botocore ansible >> $LOG_FILE 2>&1
export PATH=$PATH:/home/ec2-user/.local/bin >> ~/.bashrc
sudo -u ec2-user ansible-galaxy collection install community.general ansible.posix amazon.aws >> $LOG_FILE 2>&1

git clone https://github.com/riyaztevar/library-app.git >> $LOG_FILE 2>&1
cd library-app/ansible
ansible-playbook -v playbooks/k8s.yml -e skip_setup=false

#install kubectl client
curl -LO "https://dl.k8s.io/release/v1.31.0/bin/linux/amd64/kubectl" || echo "failed to download kubectl binary" >> $LOG_FILE
chmod +x kubectl
mv kubectl /usr/local/bin/ && echo "installed kubectl cli" >> $LOG_FILE

#copy config

mkdir /home/ec2-user/.kube
chown ec2-user.ec2-user /home/ec2-user/.kube

CTLPLANE_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=control_plane" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)

if [[ -z "$CTLPLANE_IP" ]]; then
  echo "Control plane is not found. exiting" >> $LOG_FILE
  exit
fi

count = 0
until [ "$count" == $MAX_RETRIES ]; do
  status = `curl -k -s -o /dev/null -w "%{http_code}" https://${CTLPLANE_IP}:${API_PORT}/readyz || true`
  if $status -eq 200; then
    echo "Control plane is READY! (HTTP 200 received)" >> $LOG_FILE
    scp ec2-user@${CTLPLANE_IP}:/home/ec2-user/.kube/config /home/ec2-user/.kube/config >> $LOG_FILE 2>&1
    break
  fi
  echo "control plane isn't ready. Trying again" >> $LOG_FILE
  count=$((count + 1))
  sleep 5
done