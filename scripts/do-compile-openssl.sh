#! /usr/bin/env bash
#
# Copyright (C) 2013-2014 Bilibili
# Copyright (C) 2013-2014 Zhang Rui <bbcallen@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This script is based on projects below
# https://github.com/x2on/OpenSSL-for-iPhone

#--------------------
echo "===================="
echo "[*] check host"
echo "===================="
set -e


FF_XCRUN_DEVELOPER=`xcode-select -print-path`
if [ ! -d "$FF_XCRUN_DEVELOPER" ]; then
  echo "xcode path is not set correctly $FF_XCRUN_DEVELOPER does not exist (most likely because of xcode > 4.3)"
  echo "run"
  echo "sudo xcode-select -switch <xcode path>"
  echo "for default installation:"
  echo "sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer"
  exit 1
fi

case $FF_XCRUN_DEVELOPER in  
     *\ * )
           echo "Your Xcode path contains whitespaces, which is not supported."
           exit 1
          ;;
esac


#--------------------
# include


#--------------------
# common defines
FF_PLATFORM=$1
if [ -z "$FF_PLATFORM" ]; then
    echo "You must specific an platform 'iOS, tvOS, macOS'.\n"
    exit 1
fi

FF_ARCH_FULL=$2
if [ "$FF_ARCH_FULL" = "arm64-simulator" ]; then
    FF_ARCH="arm64"
else
    FF_ARCH=$FF_ARCH_FULL
fi


FF_BUILD_ROOT=`pwd`/build
FF_TAGET_OS="darwin"


# openssl build params
export COMMON_FF_CFG_FLAGS=

OPENSSL_CFG_FLAGS=
OPENSSL_EXTRA_CFLAGS=
OPENSSL_CFG_CPU=

echo "build_root: $FF_BUILD_ROOT"

#--------------------
echo "===================="
echo "[*] config arch $FF_ARCH, $FF_ARCH_FULL"
echo "===================="

FF_BUILD_NAME="unknown"
FF_XCRUN_PLATFORM=
FF_XCRUN_OSVERSION=
FF_GASPP_EXPORT=
FF_XCODE_BITCODE=

if [ "$FF_PLATFORM" = "iOS" ]; then
    if [ "$FF_ARCH_FULL" = "x86_64" ]; then
        FF_BUILD_NAME="openssl-x86_64"
        FF_XCRUN_PLATFORM="iPhoneSimulator"
        FF_XCRUN_OSVERSION="-mios-simulator-version-min=13.0"
        OPENSSL_CFG_FLAGS="darwin64-x86_64-cc no-asm $OPENSSL_CFG_FLAGS"
    elif [ "$FF_ARCH_FULL" = "arm64" ]; then
        FF_BUILD_NAME="openssl-arm64"
        FF_XCRUN_PLATFORM="iPhoneOS"
        FF_XCRUN_OSVERSION="-miphoneos-version-min=13.0"
        OPENSSL_CFG_FLAGS="iphoneos-cross $OPENSSL_CFG_FLAGS"
    elif [ "$FF_ARCH_FULL" = "arm64-simulator" ]; then
        FF_BUILD_NAME="openssl-arm64-simulator"
        FF_XCRUN_PLATFORM="iPhoneSimulator"
        FF_XCRUN_OSVERSION="-mios-simulator-version-min=13.0"
        OPENSSL_CFG_FLAGS="darwin64-arm64-cc no-asm $OPENSSL_CFG_FLAGS"
    else
        echo "unknown architecture $FF_PLATFORM, $FF_ARCH";
        exit 1
    fi
elif [ "$FF_PLATFORM" = "macOS" ]; then
    if [ "$FF_ARCH_FULL" = "x86_64" ]; then
        FF_BUILD_NAME="openssl-x86_64"
        FF_XCRUN_PLATFORM="MacOSX"
        FF_XCRUN_OSVERSION="-DHAVE_FORK=0 -mmacosx-version-min=10.15"
        OPENSSL_CFG_FLAGS="darwin64-x86_64-cc no-asm $OPENSSL_CFG_FLAGS"
    elif [ "$FF_ARCH_FULL" = "arm64" ]; then
        FF_BUILD_NAME="openssl-arm64"
        FF_XCRUN_PLATFORM="MacOSX"
        FF_XCRUN_OSVERSION="-DHAVE_FORK=0 -mmacosx-version-min=10.15"
        OPENSSL_CFG_FLAGS="darwin64-arm64-cc no-asm $OPENSSL_CFG_FLAGS"
    else
        echo "unknown architecture $FF_PLATFORM, $FF_ARCH";
        exit 1
    fi
elif [ "$FF_PLATFORM" = "tvOS" ]; then
    if [ "$FF_ARCH_FULL" = "x86_64" ]; then
        FF_BUILD_NAME="openssl-x86_64"
        FF_XCRUN_PLATFORM="AppleTVSimulator"
        FF_XCRUN_OSVERSION="-DHAVE_FORK=0 -mtvos-simulator-version-min=13.0"
        OPENSSL_CFG_FLAGS="darwin64-x86_64-cc no-asm $OPENSSL_CFG_FLAGS"
    elif [ "$FF_ARCH_FULL" = "arm64" ]; then
        FF_BUILD_NAME="openssl-arm64"
        FF_XCRUN_PLATFORM="AppleTVOS"
        FF_XCRUN_OSVERSION="-DHAVE_FORK=0 -mtvos-version-min=13.0"
        OPENSSL_CFG_FLAGS="iphoneos-cross $OPENSSL_CFG_FLAGS"
    elif [ "$FF_ARCH_FULL" = "arm64-simulator" ]; then
        FF_BUILD_NAME="openssl-arm64-simulator"
        FF_XCRUN_PLATFORM="AppleTVSimulator"
        FF_XCRUN_OSVERSION="-DHAVE_FORK=0 -mtvos-version-min=13.0"
        OPENSSL_CFG_FLAGS="darwin64-arm64-cc no-asm $OPENSSL_CFG_FLAGS"
    else
        echo "unknown architecture $FF_PLATFORM, $FF_ARCH";
        exit 1
    fi
    FF_BUILD_SOURCE_TEMP="$FF_BUILD_ROOT/source/$FF_PLATFORM/$FF_BUILD_NAME"
    LANG=C sed -i -- 's/define HAVE_FORK 1/define HAVE_FORK 0/' "$FF_BUILD_SOURCE_TEMP/apps/speed.c"
    LANG=C sed -i -- 's/!defined(OPENSSL_NO_POSIX_IO)/defined(HAVE_FORK)/' "$FF_BUILD_SOURCE_TEMP/apps/ocsp.c"
    LANG=C sed -i -- 's/fork()/-1/' "$FF_BUILD_SOURCE_TEMP/apps/ocsp.c"
    LANG=C sed -i -- 's/fork()/-1/' "$FF_BUILD_SOURCE_TEMP/test/drbgtest.c"
    LANG=C sed -i -- 's/!defined(OPENSSL_NO_ASYNC)/defined(HAVE_FORK)/' "$FF_BUILD_SOURCE_TEMP/crypto/async/arch/async_posix.h"
else
    echo "unknown platform $FF_PLATFORM";
    exit 1
fi

echo "build_name: $FF_BUILD_NAME"
echo "platform:   $FF_XCRUN_PLATFORM"
echo "osversion:  $FF_XCRUN_OSVERSION"

#--------------------
echo "===================="
echo "[*] make ios toolchain $FF_BUILD_NAME"
echo "===================="


FF_BUILD_SOURCE="$FF_BUILD_ROOT/source/$FF_PLATFORM/$FF_BUILD_NAME"
FF_BUILD_PREFIX="$FF_BUILD_ROOT/build/$FF_PLATFORM/$FF_BUILD_NAME/output"

mkdir -p $FF_BUILD_PREFIX


FF_XCRUN_SDK=`echo $FF_XCRUN_PLATFORM | tr '[:upper:]' '[:lower:]'`
FF_XCRUN_SDK_PLATFORM_PATH=`xcrun -sdk $FF_XCRUN_SDK --show-sdk-platform-path`
FF_XCRUN_SDK_PATH=`xcrun -sdk $FF_XCRUN_SDK --show-sdk-path`
FF_XCRUN_CC="xcrun -sdk $FF_XCRUN_SDK clang"

export CROSS_TOP="$FF_XCRUN_SDK_PLATFORM_PATH/Developer"
export CROSS_SDK=`echo ${FF_XCRUN_SDK_PATH/#$CROSS_TOP\/SDKs\//}`
export BUILD_TOOL="$FF_XCRUN_DEVELOPER"
export CC="$FF_XCRUN_CC -arch $FF_ARCH $FF_XCRUN_OSVERSION"

echo "build_source: $FF_BUILD_SOURCE"
echo "build_prefix: $FF_BUILD_PREFIX"
echo "CROSS_TOP: $CROSS_TOP"
echo "CROSS_SDK: $CROSS_SDK"
echo "BUILD_TOOL: $BUILD_TOOL"
echo "CC: $CC"

#--------------------
echo "\n--------------------"
echo "[*] configurate openssl"
echo "--------------------"

OPENSSL_CFG_FLAGS="$OPENSSL_CFG_FLAGS $FF_XCODE_BITCODE"
OPENSSL_CFG_FLAGS="$OPENSSL_CFG_FLAGS --prefix=$FF_BUILD_PREFIX --openssldir=$FF_BUILD_PREFIX"

# xcode configuration
export DEBUG_INFORMATION_FORMAT=dwarf-with-dsym

cd $FF_BUILD_SOURCE
if [ -f "./Makefile" ]; then
    echo 'reuse configure'
else
    echo "config: $OPENSSL_CFG_FLAGS"
    ./Configure \
        $OPENSSL_CFG_FLAGS
    make clean
fi

#--------------------
echo "\n--------------------"
echo "[*] compile openssl"
echo "--------------------"
set +e
make -j12
make install_sw
