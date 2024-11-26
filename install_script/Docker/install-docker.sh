#!/bin/bash

set -e
# docker安装
# 1. 更新软件源
sudo apt update
sudo apt install apt-transport-https ca-certificates curl gnupg lsb-release 
# 2. 添加软件源的GPG密匙
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
# 3. 像sources.list文件中添加Docker软件源
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://mirrors.aliyun.com/docker-ce/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# 4. 安装docker
sudo apt install docker-ce docker-ce-cli containerd.io
# 5. 启动docker
sudo systemctl enable docker 
sudo systemctl start docker
# 6. 建立docker用户组
sudo groupadd docker
# 7. 将当前用户添加到docker用户组中
sudo usermod -aG docker $USER
# 8. 查看docker配置是否成功
docker run --rm hello-world



# 启动或者进入容器
# 1. 重新启动容器
docker start 容器id（可通过docker ps -a查看）
# 2. 进入容器
docker exec -it 容器id /bin/bash
# 重命名容器
docker rename 容器名  新容器名



# docker网速不好，下载不下来东西怎么办
# 参考链接：https://blog.csdn.net/Fengdf666/article/details/140236208


# 跨平台支持教程
# 1. 安装qemu
sudo apt update
sudo apt install qemu qemu-user-static
# 2. 启用多架构支持
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
# 3. 验证
docker run --rm --platform linux/arm64 ubuntu uname -m
# 4. 拉取特定架构：这里以arm架构为例
docker pull --platform linux/arm64 nginx:latest
# 5. 开始运行指定架构
docker run -it --platform linux/arm64/v8 ubuntu:latest /bin/bash
