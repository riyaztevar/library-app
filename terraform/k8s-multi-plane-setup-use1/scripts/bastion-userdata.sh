#!/bin/bash

sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

LOG_FILE="/tmp/setup.log"

cat << EOF >> /home/ec2-user/.ssh/config
Host *
  StrictHostKeyChecking no
EOF

sudo dnf install -y awscli ansible-core python-pip >> $LOG_FILE
aws secretsmanager get-secret-value --secret-id node_rsa_key --query SecretString --output text > /home/ec2-user/.ssh/id_rsa 2> $LOG_FILE
sudo chown ec2-user /home/ec2-user/.ssh/id_rsa
chmod 400 /home/ec2-user/.ssh/id_rsa

sudo mkdir /var/log/ansible
sudo chown ec2-user.ec2-user /var/log/ansible
pip3 install boto3 botocore >> $LOG_FILE 2>&1 
ansible-galaxy collection install community.general -p /home/ec2-user/.ansible/collections >> $LOG_FILE 2>&1
ansible-galaxy collection install ansible.posix -p /home/ec2-user/.ansible/collections >> $LOG_FILE 2>&1
ansible-galaxy collection install amazon.aws -p /home/ec2-user/.ansible/collections >> $LOG_FILE 2>&1

git clone https://github.com/riyaztevar/library-app.git >> $LOG_FILE 2>&1
cd library-app/ansible
ansible-playbook -v playbooks/k8s.yml -e skip_setup=false

#install kubectl client
curl -LO "https://dl.k8s.io/release/v1.31.0/bin/linux/amd64/kubectl" || echo "failed to download kubectl binary" >> $LOG_FILE
chmod +x kubectl
sudo mv kubectl /usr/local/bin/ && echo "installed kubectl cli" >> $LOG_FILE

#copy config

mkdir /home/ec2-user/.kube
scp ec2-user@${CTLPLANE_IP}:/home/ec2-user/.kube/config /home/ec2-user/.kube/config >> $LOG_FILE 2>&1
