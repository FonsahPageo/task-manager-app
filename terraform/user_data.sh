#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

# Base packages: Docker, Git, unzip (for the AWS CLI installer) and EC2 Instance Connect
apt-get update -y
apt-get install -y docker.io git curl ca-certificates unzip ec2-instance-connect

# AWS CLI v2 (Ubuntu 24.04 no longer packages awscli) for ECR login
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/aws /tmp/awscliv2.zip

# Docker daemon
systemctl enable --now docker
usermod -aG docker ubuntu

# Docker Compose v2 CLI plugin
mkdir -p /usr/libexec/docker/cli-plugins
curl -fsSL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" \
  -o /usr/libexec/docker/cli-plugins/docker-compose
chmod +x /usr/libexec/docker/cli-plugins/docker-compose

# Directory that the Jenkins pipeline deploys into
mkdir -p /opt/taskmanager
chown ubuntu:ubuntu /opt/taskmanager

aws --version
docker compose version
