#/bin/bash

set -e

# 更新软件列表
sudo apt update
sudo apt upgrade

# 安装zsh
sudo apt install zsh -y
# 验证zsh安装是否成功
zsh --version | echo "install zsh success!!"

# 安装oh-my-zsh
sudo apt-get -y install build-essential nghttp2 libnghttp2-dev libssl-dev
# curl
# sh -c "$(curl -fsSL https://gitee.com/pocmon/ohmyzsh/raw/master/tools/install.sh)"
# wget
sh -c "$(wget -O- https://gitee.com/pocmon/ohmyzsh/raw/master/tools/install.sh)"

# 安装插件
# 自动补全
git clone git@github.com:zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
# 语法高亮
git clone git@github.com:zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
# 历史命令搜索 
git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search

cd
# 安装字体
git clone https://gitee.com/chenheren/nerd-fonts.git --depth 1
cd nerd-fonts
chmod +x install.sh
./install.sh

# 切换到主目录
cd
# 安装powerlevel10k
git clone https://gitee.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k

vim ~/.zshrc

