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
FF_LIBS="libssl libcrypto"

#----------
echo_archs() {
    echo "===================="
    echo "[*] check xcode version"
    echo "===================="
    echo "FF_PLATFORM = $FF_PLATFORM"
    echo "FF_ALL_ARCHS = $FF_ALL_ARCHS"
}

do_lipo () {
    LIB_FILE=$1
    LIPO_FLAGS=
    for ARCH in $FF_ALL_ARCHS
    do
        LIPO_FLAGS="$LIPO_FLAGS $UNI_BUILD_ROOT/build/$FF_PLATFORM/openssl-$ARCH/output/lib/$LIB_FILE"
    done

    xcrun lipo -create $LIPO_FLAGS -output $UNI_BUILD_ROOT/build/$FF_PLATFORM/universal/lib/$LIB_FILE
    xcrun lipo -info $UNI_BUILD_ROOT/build/$FF_PLATFORM/universal/lib/$LIB_FILE
}

do_lipo_all () {
    mkdir -p $UNI_BUILD_ROOT/build/$FF_PLATFORM/universal/lib
    echo "lipo archs: $FF_ALL_ARCHS"
    for FF_LIB in $FF_LIBS
    do
        do_lipo "$FF_LIB.a";
    done

    cp -R $UNI_BUILD_ROOT/build/$FF_PLATFORM/openssl-x86_64/output/include $UNI_BUILD_ROOT/build/$FF_PLATFORM/universal/
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
        sh scripts/do-compile-openssl.sh $FF_PLATFORM $ARCH
    done
    do_lipo_all
elif [ "$FF_ACTION" = "clean" ]; then
    echo_archs
    for ARCH in $FF_ALL_ARCHS
    do
        cd $UNI_BUILD_ROOT/source/$FF_PLATFORM/openssl-$ARCH && git clean -xdf && cd -
    done
else
    echo "Usage:"
    echo "  compile-openssl.sh iOS build"
    echo "  compile-openssl.sh iOS clean"
    echo " ---"
    echo "  compile-openssl.sh tvOS build"
    echo "  compile-openssl.sh tvOS clean"
    echo " ---"
    echo "  compile-openssl.sh macOS build"
    echo "  compile-openssl.sh macOS clean"
    exit 1
fi
