#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

# Base packages: Docker, Git, Java 21 + Maven (for Jenkins builds) and EC2 Instance Connect
apt-get update -y
apt-get install -y docker.io git curl ca-certificates unzip ec2-instance-connect \
  openjdk-21-jdk-headless maven fontconfig

# 2 GB swap so the Jenkins build, Docker and Jenkins itself do not OOM on a 2 GB instance
if [ ! -f /swapfile ]; then
  fallocate -l 4G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# AWS CLI v2 (Ubuntu 24.04 no longer packages awscli) for ECR login
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/aws /tmp/awscliv2.zip

# Node.js 20 LTS installed system-wide so Jenkins (jenkins user) can find npm on PATH
NODE_TARBALL="$(curl -fsSL https://nodejs.org/dist/latest-v20.x/ | grep -oE 'node-v[0-9.]+-linux-x64\.tar\.xz' | sort -V | tail -1)"
curl -fsSL "https://nodejs.org/dist/latest-v20.x/${NODE_TARBALL}" -o /tmp/node.tar.xz
tar -xJf /tmp/node.tar.xz -C /opt
ln -sf "/opt/${NODE_TARBALL%.tar.xz}/bin/node" /usr/bin/node
ln -sf "/opt/${NODE_TARBALL%.tar.xz}/bin/npm" /usr/bin/npm
ln -sf "/opt/${NODE_TARBALL%.tar.xz}/bin/npx" /usr/bin/npx
rm -f /tmp/node.tar.xz
node --version
npm --version

# Docker daemon
systemctl enable --now docker
usermod -aG docker ubuntu

# Docker Compose v2 CLI plugin
mkdir -p /usr/libexec/docker/cli-plugins
curl -fsSL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" \
  -o /usr/libexec/docker/cli-plugins/docker-compose
chmod +x /usr/libexec/docker/cli-plugins/docker-compose

# Directory that the Jenkins pipeline deploys into (before Jenkins install so it
# exists even if the Jenkins apt step fails)
mkdir -p /opt/taskmanager
chown ubuntu:ubuntu /opt/taskmanager

# Jenkins (official Debian repository), on port 8080.
# Jenkins rotates its apt signing key yearly; pick the newest available one.
for jenkey in jenkins.io-2027.key jenkins.io-2026.key jenkins.io-2025.key jenkins.io-2024.key jenkins.io-2023.key; do
  if curl -fsSL --max-time 30 "https://pkg.jenkins.io/debian-stable/${jenkey}" -o /usr/share/keyrings/jenkins-keyring.asc; then
    break
  fi
done
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  > /etc/apt/sources.list.d/jenkins.list
apt-get update -y
apt-get install -y jenkins
systemctl enable --now jenkins

aws --version
docker compose version
java -version
mvn -v
node --version
