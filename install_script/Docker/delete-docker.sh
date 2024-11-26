#!/bin/bash

set -e

sudo apt-get purge -y docker-ce docker-ce-cli containerd.io

sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd

sudo rm -rf /etc/docker
sudo rm -f /etc/systemd/system/docker.service
sudo rm -f /etc/systemd/system/docker.socket

rm -rf ~/.docker
sudo rm -f /etc/apt/sources.list.d/docker.list
sudo systemctl daemon-reload
sudo rm -f /usr/share/keyrings/docker-archive-keyring.gpg
sudo apt-get update
