#! /usr/bin/env bash
#
# Copyright (C) 2013-2015 Bilibili
# Copyright (C) 2013-2015 Zhang Rui <bbcallen@gmail.com>
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

IJK_OPENSSL_UPSTREAM=https://github.com/openssl/openssl.git
IJK_OPENSSL_FORK=https://github.com/openssl/openssl.git
IJK_OPENSSL_COMMIT=$2
IJK_OPENSSL_LOCAL_REPO=build/extra/openssl

set -e

FF_ALL_ARCHS=
FF_ALL_ARCHS_IOS="armv7 arm64 i386 x86_64"
FF_ALL_ARCHS_TVOS="arm64 x86_64"
FF_ALL_ARCHS_MACOS="x86_64"

FF_PLATFORM=$1

function pull_common() {
    echo "== pull openssl base =="
    sh scripts/pull-repo-base.sh $IJK_OPENSSL_UPSTREAM $IJK_OPENSSL_LOCAL_REPO
}

function pull_fork() {
    echo "== pull openssl fork $1 =="
    sh scripts/pull-repo-ref.sh $IJK_OPENSSL_FORK build/source/$FF_PLATFORM/openssl-$1 ${IJK_OPENSSL_LOCAL_REPO}
    cd build/source/$FF_PLATFORM/openssl-$1
    git checkout ${IJK_OPENSSL_COMMIT} -B SGPlayer
    cd -
}

function pull_fork_all() {
    for ARCH in $FF_ALL_ARCHS
    do
        pull_fork $ARCH
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

pull_common
pull_fork_all

