#!/bin/bash

# 安装教程可参考链接：https://docs.docker.com/engine/install/ubuntu/
# https://www.cnblogs.com/echohye/p/18712755
# https://blog.csdn.net/qq_55272229/article/details/145394163

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



# 拉取镜像
docker pull ubuntu:latest
# 基于拉取的镜像创建一个新的容器
docker run -it --name my_ubuntu_container ubuntu:latest /bin/bash
# 重新启动容器
docker start 容器id（可通过docker ps -a查看）
# 进入容器
docker exec -it 容器id /bin/bash
# 重命名容器
docker rename 容器名  新容器名
# 停止容器
docker stop my_ubuntu_container
# 删除容器
docker rm my_ubuntu_container



# 彻底删除docker相关配置
# 1. 停止 Docker 服务
sudo systemctl stop docker
sudo systemctl stop containerd
# 2. 卸载 Docker 相关软件
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo apt-get autoremove -y
# 3. 删除所有 Docker 相关的文件
sudo rm -rf /var/lib/docker           # Docker 数据（镜像、容器、网络等）
sudo rm -rf /var/lib/containerd       # Containerd 数据
sudo rm -rf /etc/docker               # Docker 配置文件
sudo rm -rf /run/docker.sock          # Docker 进程 socket 文件
sudo rm -rf ~/.docker                  # 用户 Docker 配置（需要删除当前用户的 Docker 目录）
# 4. 删除 Docker 相关的 APT 源
sudo rm -f /etc/apt/sources.list.d/docker.list
sudo apt-get update
# 5. 删除 Docker GPG 密钥
sudo rm -f /etc/apt/keyrings/docker.gpg
# 6. 删除 Docker 用户组
sudo groupdel docker



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
