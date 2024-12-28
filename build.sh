#!/bin/bash

CUR_DIR=$(pwd)

# 编译参数设置
ARCH=aarch64
CROSS_COMPILE=aarch64-linux-gnu
CROSS_COMPILE_PATH=/home/ss/WorkSpace/TspLinux/prebuilts/gcc/linux-x86/aarch64/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin
DCMAKE_TOOLCHAIN_FILE=$CUR_DIR/aarch64-linux.cmake
export PATH=$CROSS_COMPILE_PATH:$PATH

# 安装路径
INSTALL_DIR=$CUR_DIR/install
SYSFSUTILS_INSTALL_DIR=$INSTALL_DIR/sysfsutils
LIBHUGETLBFS_INSTALL_DIR=$INSTALL_DIR/libhugetlbfs
LIBMETAL_INSTALL_DIR=$INSTALL_DIR/libmetal
OPENAMP_INSTALL_DIR=$INSTALL_DIR/openamp

export LIBSYSFS_PATH=$SYSFSUTILS_INSTALL_DIR
export LIBMETAL_PATH=$LIBMETAL_INSTALL_DIR

show_help(){
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h, --help          Display this information"
    echo "  -c, --clean         Clean build"
    echo "  -s, --sysfsutils    Build sysfsutils"
    echo "  -lh, --libhugetlbfs Build libhugetlbfs"
    echo "  -lm, --libmetal     Build libmetal"
    echo "  -oa, --openamp      Build OpenAMP"
}

check_source_dir_is_exist(){
    if [ ! -d "$CUR_DIR/libhugetlbfs" ]; then
        echo "Directory $CUR_DIR/libhugetlbfs does not exist. Cloning repository..."
        git clone "https://github.com/libhugetlbfs/libhugetlbfs.git" "$CUR_DIR/libhugetlbfs"
        if [ $? -eq 0 ]; then
            echo "Repository cloned successfully to libhugetlbfs."
        else
            echo "Failed to clone repository of libhugetlbfs."
            exit 1
        fi
    fi

    if [ ! -d "$CUR_DIR/sysfsutils" ]; then
        echo "Directory $CUR_DIR/sysfsutils does not exist. Cloning repository..."
        git clone "https://github.com/linux-ras/sysfsutils.git" "$CUR_DIR/sysfsutils"
        if [ $? -eq 0 ]; then
            echo "Repository cloned successfully to sysfsutils."
        else
            echo "Failed to clone repository of sysfsutils."
            exit 1
        fi
    fi

    if [ ! -d "$CUR_DIR/libmetal" ]; then
        echo "Directory $CUR_DIR/libmetal does not exist. Cloning repository..."
        git clone "https://github.com/OpenAMP/libmetal.git" "$CUR_DIR/libmetal"
        if [ $? -eq 0 ]; then
            echo "Repository cloned successfully to libmetal."
        else
            echo "Failed to clone repository of libmetal."
            exit 1
        fi
    fi

    if [ ! -d "$CUR_DIR/open-amp" ]; then
        echo "Directory $CUR_DIR/open-amp does not exist. Cloning repository..."
        git clone "https://github.com/OpenAMP/open-amp" "$CUR_DIR/open-amp"
        if [ $? -eq 0 ]; then
            echo "Repository cloned successfully to open-amp."
        else
            echo "Failed to clone repository of open-amp."
            exit 1
        fi
    fi
}

# 编译sysfsutils
build_sysfsutils(){
    mkdir -p "$SYSFSUTILS_INSTALL_DIR"
    cd $CUR_DIR/sysfsutils || { echo "sysfsutils directory does not exist"; exit 1; }
    autoreconf -ivf
    ./configure --host=$CROSS_COMPILE --prefix="$SYSFSUTILS_INSTALL_DIR" || { echo "Configure failed"; exit 1; }
    make CC=$CROSS_COMPILE-gcc || { echo "Make failed"; exit 1; }
    make install || { echo "Install failed"; exit 1; }
}

# 编译libhugetlbfs
build_libhugetlbfs(){
    mkdir -p "$LIBHUGETLBFS_INSTALL_DIR"
    cd $CUR_DIR/libhugetlbfs || { echo "libhugetlbfs directory does not exist"; exit 1; }
    ./autogen.sh || { echo "Autogen failed"; exit 1; }
    ./configure --host=$CROSS_COMPILE --prefix="$LIBHUGETLBFS_INSTALL_DIR" || { echo "Configure failed"; exit 1; }
    make ARCH=$ARCH CC=$CROSS_COMPILE-gcc LD=$CROSS_COMPILE-ld || { echo "Make failed"; exit 1; }
    # TO DO: install has some problem
    # make install-libs
}

# 编译libmetal
build_libmetal(){
    mkdir -p $CUR_DIR/libmetal/build
    cd $CUR_DIR/libmetal/build
    cmake ../ -DCMAKE_TOOLCHAIN_FILE=$DCMAKE_TOOLCHAIN_FILE
    make VERBOSE=1 DESTDIR=$LIBMETAL_INSTALL_DIR install
}

# 编译OpenAMP
build_openamp(){
    mkdir -p $CUR_DIR/open-amp/build
    cd $CUR_DIR/open-amp/build
    cmake ../ -DCMAKE_TOOLCHAIN_FILE=$DCMAKE_TOOLCHAIN_FILE
    make VERBOSE=1 DESTDIR=$OPENAMP_INSTALL_DIR install
}

# 清理编译
clean(){
    echo "**********************************Clean sysfsutils...*********************************"
    cd $CUR_DIR/sysfsutils || { echo "sysfsutils directory does not exist"; exit 1; }
    make clean
    echo "********************************Clean libhugetlbfs...*********************************"
    cd $CUR_DIR/libhugetlbfs || { echo "libhugetlbfs directory does not exist"; exit 1; }
    make clean
    echo "**********************************Clean libmetal...***********************************"
    cd $CUR_DIR/libmetal/ || { echo "libmetal directory does not exist"; exit 1; }
    rm -rf build
    echo "***********************************Clean openamp...***********************************"
    cd $CUR_DIR/open-amp/ || { echo "open-amp directory does not exist"; exit 1; }
    rm -rf build
    echo "***********************************Clean install...***********************************"
    rm -rf $INSTALL_DIR/*
}

# 主函数
check_source_dir_is_exist
mkdir -p $INSTALL_DIR
while [ "$1" != "" ]; do
    case $1 in
        -h | --help ) 
            show_help
            exit 0
            ;;
        -c | --clean ) 
            clean
            exit 0
            ;;
        -s | --sysfsutils ) 
            build_sysfsutils
            exit 0
            ;;
        -lh | --libhugetlbfs ) 
            build_libhugetlbfs
            exit 0
            ;;
        -lm | --libmetal ) 
            build_libmetal
            exit 0
            ;;
        -oa | --openamp ) 
            build_openamp
            exit 0
            ;;
        * ) 
            show_help
            exit 1
            ;;
    esac
    shift
done

build_sysfsutils
# build_libhugetlbfs
build_libmetal
build_openamp

exit 0
