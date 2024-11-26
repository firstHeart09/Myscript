#!/bin/bash

set -e

# Update the source of software
apt update

# Install build-essential
apt install build-essential
# Install wget to get source code
apt install wget 

# Install ang configure git
apt install git
git config --global user.name "firstHeart09"
git config --global user.email "du1274455999@163.com"

ssh-keygen -t rsa -b 4096 -C "du1274455999@163.com"

ssh-keyscan github.com >> /root/.ssh/known_hosts

cat /root/.ssh/id_rsa.pub

