#!/bin/bash

set -e

# install tools
# apt install flex bison gawk rsync 

if [ $# -ne 1 ]; then
        echo "use: $0 [option1]
	可以使用的选项如下：
	  init:         解压缩gz文件，并创建tools目录保存生成的交叉编译工具
          binutils:     配置和安装binutils
	  linux:        配置和安装linux系统头文件，因为第二遍编译GCCs生成C库的时候需要用到）
	  pass1-gcc:    配置和安装与GCC相关的这一套工具（不包括共享库）
	  glibc:        安装标准C库头文件和启动文件
	  libgcc:       安装编译器支持库
	  all-glibc:    安装标准C库
          pass2-gcc:    配置和安装all GCC，包括所依赖的共享库等
          delete:       删除tools目录与解压缩出来的所有文件
          source:       获取gz文件，包括gcc、glibc、binutils等
        如果想要使用glibc安装交叉编译工具，则推荐安装顺序为：init -> binutils -> linux -> pass1-gcc -> glibc -> libgcc -> all-glibc -> pass2-gcc
	"
        exit 1
fi

TARGET="aarch64-linux"

# all
if [ "$1" == "all" ]; then
	$0 delete
	$0 init
	$0 linux
	$0 binutils
	$0 pass1-gcc
	$0 glibc
	$0 libgcc
	$0 all-glibc
	$0 pass2-gcc
fi

# init
if [ "$1" == "init" ]; then
	cd ${HOME}/across-toolchain-glibc/source
	for f in *.tar.gz; do tar -zxvf $f; done
	tar -xvJf linux-3.17.2.tar.xz
	# tar -xvJf glibc-2.39.tar.xz
	mkdir ${HOME}/across-toolchain-glibc/tools
	echo "解压操作完成，并且完成文件夹的初始化，接下来请执行:  $0 binutils"
fi


# step1: binutils
if [ "$1" == "binutils" ]; then 
        cd ${HOME}/across-toolchain-glibc/source/binutils-2.37        
	if [ -d "build" ]; then
	# 	cd build && make distclean
		rm -rf build
	fi
	mkdir build && cd build
	../configure --target=${TARGET} --prefix=${HOME}/across-toolchain-glibc/tools \
		--disable-multilib --disable-nls --disable-werror --enable-install-libbfd --enable-install-libiberty \
		--with-pkgversion="Self across toolchain with glibc and binutils-2.37" -v 2>&1 | tee binutils-configure.log
        make -j4 2>&1 | tee binutils-make.log
        make install 2>&1 | tee binutils-make-install.log
	echo "binutils 安装完成, 接下来请执行:  $0 linux"
fi

# step2: linux keneral header file
if [ "$1" == "linux" ]; then
	cd ${HOME}/across-toolchain-glibc/source/linux-3.17.2
	make ARCH=arm64 headers_install INSTALL_HDR_PATH=${HOME}/across-toolchain-glibc/tools/${TARGET}
	echo "linxu内核头文件安装完成，接下来请执行： $0 pass1-gcc"
fi

# step3: 安装c/c++编译器
if [ "$1" == "pass1-gcc" ]; then
	cd ${HOME}/across-toolchain-glibc/source/gcc-13.2.0
	if [ -d "build-pass1" ]; then
		cd build-pass1 && make distclean
		rm -rf ../build-pass1
	fi
	mkdir build-pass1 && cd build-pass1
	../configure --target=${TARGET} --prefix=${HOME}/across-toolchain-glibc/tools \
                --disable-multilib --without-headers --with-native-system-header=/usr/include \
                --enable-languages=c,c++,go \
                --disable-decimal-float --disable-libffi --disable-lto --enable-libgomp --disable-libmudflap --disable-libquadmath \
                --disable-libssp --disable-nls --disable-shared \
		--disable-tls \
                --with-as=${HOME}/across-toolchain-glibc/source/binutils-2.37/build/gas/as-new \
                --with-ld=${HOME}/across-toolchain-glibc/source/binutils-2.37/build/ld/ld-new \
		--with-pkgversion="Self across toolchain with glibc and gcc-13.2.0" \
                --enable-threads=posix 2>&1 | tee pass1-configure.log
	make -j4 all-gcc 2>&1 | tee pass1-make-all-gcc.log
	make install-gcc 2>&1 | tee pass1-make-install-gcc.log
	echo "安装C/C++编译器完成，接下来请执行： $0 glibc"
fi

# step4: 安装标准C库头文件和启动文件
if [ "$1" == "glibc" ]; then
	cd ${HOME}/across-toolchain-glibc/source/glibc-2.39
	if [ -d "build" ]; then
		rm -rf build
	fi
	mkdir build && cd build
	# 注意：glibc的configure中没有--target，glibc使用--host指定目标平台（可以通过./configure --help查看system type进行确定）
	../configure --host=${TARGET} --host=${TARGET} --target=${TARGET} --prefix=${HOME}/across-toolchain-glibc/tools/${TARGET} \
		--with-headers=${HOME}/across-toolchain-glibc/tools/${TARGET}/include \
		--disable-multilib --disable-profile \
		--enable-threads=posix \
		# CFLAGS_FOR_TARGET="-mcpu=arm7tdmi -marm -march=armv4t -mabi=aapcs-linux -g -O0" \
		--disable-tls \
		-v --disable-werror \
		libc_cv_forced_unwind=yes libc_cv_c_cleanup=yes libc_cv_ctors_header=yes \
		--with-pkgversion="Self across toolchain with glibc and glibc-2.39" \
		2>&1 | tee glibc-configure.log
	make install-bootstrap-headers=yes install-headers
	make -j4 csu/subdir_lib
	install csu/crt1.o csu/crti.o csu/crtn.o ${HOME}/across-toolchain-glibc/tools/${TARGET}/lib
	${TARGET}-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o ${HOME}/across-toolchain-glibc/tools/${TARGET}/lib/libc.so
	touch ${HOME}/across-toolchain-glibc/tools/${TARGET}/include/gnu/stubs.h
	echo "安装标准C库头文件和启动文件成功，接下来请执行： $0 libgcc"
fi

# step5: 安装编译器支持库
if [ "$1" == "libgcc" ]; then
	cd ${HOME}/across-toolchain-glibc/source/gcc-13.2.0/build-pass1
	make -j4 all-target-libgcc
	make install-target-libgcc
	echo "安装编译器支持库完成，接下来请执行： $0 all-glibc"
fi

# step6：安装标准C库
if [ "$1" == "all-glibc" ]; then
	cd ${HOME}/across-toolchain-glibc/source/glibc-2.39/build
	make -j4
	make install
	echo "安装标准C库完成，接下来请执行： $0 pass2-gcc"
fi

# step7: 完成最后的构建
if [ "$1" == "pass2-gcc" ]; then
	cd ${HOME}/across-toolchain-glibc/source/gcc-13.2.0
	if [ -d "build-pass2" ]; then
		cd build-pass2 && make distclean
		rm -rf ../build-pass2
	fi
	mkdir build-pass2 && cd build-pass2
	../configure --build=x86_64-pc-linux-gnu --host=x86_64-pc-linux-gnu --target=${TARGET} \
                --prefix=${HOME}/across-toolchain-glibc/tools/${TARGET}/\
                --with-sysroot=${HOME}/across-toolchain-glibc/tools/${TARGET} \
                --with-headers=${HOME}/across-toolchain-glibc/tools/${TARGET}/usr/include \
                # CFLAGS_FOR_TARGET="-mcpu=arm7tdmi -marm -march=armv4t -mabi=aapcs-linux -g -O0" \
                --with-native-system-header=/usr/include \
                --disable-multilib --disable-symvers --disable-libstdc++-v3 \
                --enable-languages=c,c++,go \
                --disable-decimal-float --disable-libffi --disable-lto --disable-libgomp --disable-libmudflap \
                --disable-libquadmath --disable-libstdcxx-pch --disable-libssp --disable-nls --enable-shared \
                --disable-tls \
                --with-as=${HOME}/across-toolchain-glibc/source/binutils-2.37/build/gas/as-new \
                --with-ld=${HOME}/across-toolchain-glibc/source/binutils-2.37/build/ld/ld-new \
		--with-pkgversion="Self across toolchain with glibc and gcc-13.2.0" \
                --enable-threads=posix 2>&1 | tee pass2-configure.log
	make -j4 2>&1 | tee pass2-make-all.log
	make install 2>&1 | tee pass2-make-install.log
	echo "整个工具构建过程完成"
fi

# delete
if [ "$1" == "delete" ]; then
	cd ${HOME}/across-toolchain-glibc/source
	rm -rf binutils-2.37 gcc-13.2.0 glibc-2.39 linux-3.17.2
	cd ${HOME}/across-toolchain-glibc
	rm -rf tools
	echo "删除无用文件完成，接下来请执行： $0 init"
fi

# get source code
if [ "$1" == "source" ]; then
	cd ${HOME}/across-toolchain-glibc/source
	wget https://ftp.gnu.org/gnu/binutils/binutils-2.37.tar.gz
	wget https://ftp.gnu.org/gnu/gcc/gcc-13.2.0/gcc-13.2.0.tar.gz
	wget https://ftp.sjtu.edu.cn/sites/ftp.kernel.org/pub/linux/kernel/v6.x/linux-6.1.10.tar.xz
	wget https://ftp.gnu.org/pub/gnu/glibc/glibc-2.39.tar.gz
	echo "源码下载完成，接下来请执行： $0 init"
fi
