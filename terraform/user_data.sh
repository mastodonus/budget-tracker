#!/bin/bash
set -e

# Export path
echo "$(date '+%Y-%m-%d %H:%M:%S') >> exporting path" >> /home/ec2-user/user_data.log
export PATH=$PATH:/usr/local/bin

# Update packages
echo "$(date '+%Y-%m-%d %H:%M:%S') >> updating packages" >> /home/ec2-user/user_data.log
sudo dnf update -y

# Install dependencies
echo "$(date '+%Y-%m-%d %H:%M:%S') >> installing dependencies" >> /home/ec2-user/user_data.log
sudo dnf install -y  git gcc make docker
sudo dnf install -y  openssl-devel readline-devel zlib-devel
sudo dnf install -y  libyaml-devel libffi-devel
sudo dnf install -y  nodejs nginx postgresql15-server postgresql15

##################################################
# Docker Setup
##################################################
# Enable and start Docker
echo "$(date '+%Y-%m-%d %H:%M:%S') >> starting docker" >> /home/ec2-user/user_data.log
sudo systemctl enable docker
sudo systemctl start docker

# Add ec2-user to docker group
echo "$(date '+%Y-%m-%d %H:%M:%S') >> creating docker user group" >> /home/ec2-user/user_data.log
sudo usermod -aG docker ec2-user
newgrp docker

# Install docker-compose
echo "$(date '+%Y-%m-%d %H:%M:%S') >> installing docker compose" >> /home/ec2-user/user_data.log
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

##################################################
# PostgreSQL Setup
##################################################

# Wait until a second disk appears
echo "$(date '+%Y-%m-%d %H:%M:%S') >> detecting EBS volume" >> /home/ec2-user/user_data.log
while [ $(lsblk -dn -o NAME | wc -l) -lt 2 ]; do
  echo "$(date '+%Y-%m-%d %H:%M:%S') >> waiting for EBS volume" >> /home/ec2-user/user_data.log
  sleep 5
done

# Find the non-root disk
DEVICE=$(lsblk -dn -o NAME,TYPE | awk '$2=="disk"{print $1}' | grep -v nvme0n1 | head -n1)
DEVICE_PATH="/dev/$DEVICE"
echo "$(date '+%Y-%m-%d %H:%M:%S') >> using device $DEVICE_PATH" >> /home/ec2-user/user_data.log

# Format the disk
echo "$(date '+%Y-%m-%d %H:%M:%S') >> formatting $DEVICE_PATH" >> /home/ec2-user/user_data.log
if ! blkid $DEVICE_PATH; then
  sudo mkfs -t ext4 $DEVICE_PATH
fi

# Postgres data directory
echo "$(date '+%Y-%m-%d %H:%M:%S') >> setting up postgres data directory" >> /home/ec2-user/user_data.log
sudo mkdir -p /var/lib/postgresql/data
sudo mount $DEVICE_PATH /var/lib/postgresql/data
sudo chown -R ec2-user:ec2-user /var/lib/postgresql/data

# Persist mount across reboots
echo "$DEVICE_PATH /var/lib/postgresql/data ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab

# Initialize database in mounted directory
echo "$(date '+%Y-%m-%d %H:%M:%S') >> initializing database" >> /home/ec2-user/user_data.log
sudo /usr/bin/postgresql-setup --initdb

##################################################
# Nginx
##################################################

# Start nginx
echo "$(date '+%Y-%m-%d %H:%M:%S') >> starting nginx" >> /home/ec2-user/user_data.log
sudo systemctl start nginx
sudo systemctl enable nginx