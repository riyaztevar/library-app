#!/bin/bash

sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

cat << EOF >> /home/ec2-user/.ssh/config
Host *
  StrictHostKeyChecking no
EOF