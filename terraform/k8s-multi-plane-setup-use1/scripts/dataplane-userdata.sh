#!/bin/bash

sudo dnf install -y git ansible-core awscli
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix

ansible-pull -U https://github.com/riyaztevar/library-ansible-config.git -e skip_setup=false >> /tmp/ansible-pull.log 2>&1



