#!/bin/bash

# 脚本遇到错误时立即退出，并打印错误所在的行号
set -euo pipefail

# 安装必要的依赖
echo "Installing dependencies..."
sudo apt update
sudo apt install -y build-essential cmake ninja-build python3 \
                    libxml2-dev zlib1g-dev libncurses5-dev \
                    libtinfo-dev curl git lld clang

# 设置安装路径和构建目录
INSTALL_DIR="${HOME}/Llvm/tools/"
BUILD_DIR="${HOME}/Llvm/source/"

echo "Installation Directory: $INSTALL_DIR"
echo "Build Directory: $BUILD_DIR"

# 确保目录存在
mkdir -p "${HOME}/source" "${INSTALL_DIR}"

# 进入源码目录
cd "${HOME}/source"

# 克隆LLVM源码（如果不存在则克隆）
if [ ! -d "llvm-project" ]; then
  echo "Cloning LLVM repository..."
  git clone git@github.com:llvm/llvm-project.git
else
  echo "LLVM repository already exists, pulling latest changes..."
  cd llvm-project && git pull && cd ..
fi

# 创建并进入构建目录
mkdir -p "${BUILD_DIR}/build"
cd "${BUILD_DIR}/build"

# 配置 CMake
cmake -G Ninja ../../llvm-project/llvm \
    -DLLVM_TARGETS_TO_BUILD="X86;AArch64" \
    -DCMAKE_BUILD_TYPE="DEBUG" \
    -DLLVM_ENABLE_ASSERTIONS=ON \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DLLVM_ENABLE_PROJECTS="clang;lld;compiler-rt" \
    -DLLVM_USE_LINKER=lld \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR"

# 编译LLVM及Clang
echo "Building LLVM and Clang with LTO support... This may take a while."
ninja

# 安装到指定目录
echo "Installing LLVM and Clang to $INSTALL_DIR..."
ninja install

# 配置环境变量
echo "Configuring environment variables..."
PROFILE_SCRIPT="/etc/profile.d/llvm.sh"

if ! grep -q "$INSTALL_DIR/bin" <<< "$PATH"; then
  echo "export PATH=$INSTALL_DIR/bin:\$PATH" | sudo tee "$PROFILE_SCRIPT"
fi
source "$PROFILE_SCRIPT"

# 验证安装及LTO支持
echo "Verifying installation..."
clang --version

echo "Testing LTO support..."
echo 'int main() { return 0; }' > test.c
clang -O2 -flto test.c -o test
if ldd test | grep -q 'not a dynamic executable'; then
  echo "LTO build successful!"
else
  echo "LTO build failed!"
fi

# 清理测试文件
rm test.c test

echo "LLVM/Clang with LTO support installed successfully!"

