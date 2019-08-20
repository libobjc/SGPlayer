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

#----------
# modify for your build tool

set -e

FF_ALL_ARCHS=
FF_ALL_ARCHS_IOS="armv7 arm64 i386 x86_64"
FF_ALL_ARCHS_TVOS="arm64 x86_64"
FF_ALL_ARCHS_MACOS="x86_64"

FF_PLATFORM=$1
FF_ACTION=$2

#----------
UNI_BUILD_ROOT=`pwd`/build
UNI_TMP="$UNI_BUILD_ROOT/build/tmp"
UNI_TMP_LLVM_VER_FILE="$UNI_TMP/llvm.ver.txt"

#----------
SSL_LIBS="libcrypto libssl"
FF_LIBS="libavcodec libavfilter libavformat libavutil libswscale libswresample"

#----------
echo_archs() {
    echo "===================="
    echo "[*] check xcode version"
    echo "===================="
    echo "FF_PLATFORM = $FF_PLATFORM"
    echo "FF_ALL_ARCHS = $FF_ALL_ARCHS"
}

do_lipo_ffmpeg () {
    LIB_FILE=$1
    LIPO_FLAGS=
    for ARCH in $FF_ALL_ARCHS
    do
        ARCH_LIB_FILE="$UNI_BUILD_ROOT/build/$FF_PLATFORM/ffmpeg-$ARCH/output/lib/$LIB_FILE"
        if [ -f "$ARCH_LIB_FILE" ]; then
            LIPO_FLAGS="$LIPO_FLAGS $ARCH_LIB_FILE"
        else
            echo "skip $LIB_FILE of $ARCH";
        fi
    done

    xcrun lipo -create $LIPO_FLAGS -output $UNI_BUILD_ROOT/build/$FF_PLATFORM/universal/lib/$LIB_FILE
    xcrun lipo -info $UNI_BUILD_ROOT/build/$FF_PLATFORM/universal/lib/$LIB_FILE
}

do_lipo_ssl () {
    LIB_FILE=$1
    LIPO_FLAGS=
    for ARCH in $FF_ALL_ARCHS
    do
        ARCH_LIB_FILE="$UNI_BUILD_ROOT/build/$FF_PLATFORM/openssl-$ARCH/output/lib/$LIB_FILE"
        if [ -f "$ARCH_LIB_FILE" ]; then
            LIPO_FLAGS="$LIPO_FLAGS $ARCH_LIB_FILE"
        else
            echo "skip $LIB_FILE of $ARCH";
        fi
    done

    if [ "$LIPO_FLAGS" != "" ]; then
        xcrun lipo -create $LIPO_FLAGS -output $UNI_BUILD_ROOT/build/$FF_PLATFORM/universal/lib/$LIB_FILE
        xcrun lipo -info $UNI_BUILD_ROOT/build/$FF_PLATFORM/universal/lib/$LIB_FILE
    fi
}

do_lipo_all () {
    mkdir -p $UNI_BUILD_ROOT/build/$FF_PLATFORM/universal/lib
    echo "lipo archs: $FF_ALL_ARCHS"
    for FF_LIB in $FF_LIBS
    do
        do_lipo_ffmpeg "$FF_LIB.a";
    done

    ANY_ARCH=
    for ARCH in $FF_ALL_ARCHS
    do
        ARCH_INC_DIR="$UNI_BUILD_ROOT/build/$FF_PLATFORM/ffmpeg-$ARCH/output/include"
        if [ -d "$ARCH_INC_DIR" ]; then
            if [ -z "$ANY_ARCH" ]; then
                ANY_ARCH=$ARCH
                cp -R "$ARCH_INC_DIR" "$UNI_BUILD_ROOT/build/$FF_PLATFORM/universal/"
            fi

            UNI_INC_DIR="$UNI_BUILD_ROOT/build/$FF_PLATFORM/universal/include"

            mkdir -p "$UNI_INC_DIR/libavutil/$ARCH"
            cp -f "$ARCH_INC_DIR/libavutil/avconfig.h"  "$UNI_INC_DIR/libavutil/$ARCH/avconfig.h"
            cp -f scripts/avconfig.h                    "$UNI_INC_DIR/libavutil/avconfig.h"
            cp -f "$ARCH_INC_DIR/libavutil/ffversion.h" "$UNI_INC_DIR/libavutil/$ARCH/ffversion.h"
            cp -f scripts/ffversion.h                   "$UNI_INC_DIR/libavutil/ffversion.h"
            mkdir -p "$UNI_INC_DIR/libffmpeg/$ARCH"
            cp -f "$ARCH_INC_DIR/libffmpeg/config.h"    "$UNI_INC_DIR/libffmpeg/$ARCH/config.h"
            cp -f scripts/config.h                      "$UNI_INC_DIR/libffmpeg/config.h"
        fi
    done

    for SSL_LIB in $SSL_LIBS
    do
        do_lipo_ssl "$SSL_LIB.a";
    done
}

#----------
if [ "$FF_PLATFORM" = "iOS" ]; then
    FF_ALL_ARCHS=$FF_ALL_ARCHS_IOS
elif [ "$FF_PLATFORM" = "tvOS" ]; then
    FF_ALL_ARCHS=$FF_ALL_ARCHS_TVOS
elif [ "$FF_PLATFORM" = "macOS" ]; then
    FF_ALL_ARCHS=$FF_ALL_ARCHS_MACOS
else
    echo "You must specific an platform 'iOS, tvOS, macOS'.\n"
    exit 1
fi

if [ "$FF_ACTION" = "build" ]; then
    echo_archs
    for ARCH in $FF_ALL_ARCHS
    do
        sh scripts/do-compile-ffmpeg.sh $FF_PLATFORM $ARCH
    done
    do_lipo_all
elif [ "$FF_ACTION" = "clean" ]; then
    echo_archs
    echo "=================="
    for ARCH in $FF_ALL_ARCHS
    do
        echo "clean ffmpeg-$ARCH"
        echo "=================="
        cd $UNI_BUILD_ROOT/source/$FF_PLATFORM/ffmpeg-$ARCH && git clean -xdf && cd -
    done
    echo "clean build cache"
    echo "================="
    rm -rf $UNI_BUILD_ROOT/build/$FF_PLATFORM/ffmpeg-*
    rm -rf $UNI_BUILD_ROOT/build/$FF_PLATFORM/openssl-*
    rm -rf $UNI_BUILD_ROOT/build/$FF_PLATFORM/universal/include
    rm -rf $UNI_BUILD_ROOT/build/$FF_PLATFORM/universal/lib
    echo "clean success"
else
    echo "Usage:"
    echo "  compile-ffmpeg.sh iOS build"
    echo "  compile-ffmpeg.sh iOS clean"
    echo " ---"
    echo "  compile-ffmpeg.sh tvOS build"
    echo "  compile-ffmpeg.sh tvOS clean"
    echo " ---"
    echo "  compile-ffmpeg.sh macOS build"
    echo "  compile-ffmpeg.sh macOS clean"
    exit 1
fi

