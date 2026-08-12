#!/bin/bash

subnet_id=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=control_plane" \
        --query "Reservations[*].Instances[*].SubnetId" \
        --output text)
aws ec2 describe-subnets --subnet-ids ${subnet_id} \
    --query "Subnets[*].CidrBlock" \
    --output text