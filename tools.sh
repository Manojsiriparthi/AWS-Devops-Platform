#!/bin/bash

# Update packages
apt update -y

# Install Java
apt install -y fontconfig openjdk-21-jre

# Verify Java
java -version

# Add Jenkins repository key
wget -O /usr/share/keyrings/jenkins-keyring.asc \
https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

# Add Jenkins repository
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
> /etc/apt/sources.list.d/jenkins.list

# Update package list
apt update -y

# Install Jenkins
apt install -y jenkins

# Enable and start Jenkins
systemctl enable jenkins
systemctl start jenkins

# Check Jenkins status
systemctl status jenkins
