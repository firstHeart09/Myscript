#!/bin/bash

for pkg in docker \
           docker-engine \
           docker.io \
           docker-doc \
           docker-compose \
           podman-docker \
           containerd \
           runc;
do
    sudo apt remove $pkg;
done
