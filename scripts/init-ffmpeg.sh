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

IJK_FFMPEG_UPSTREAM=https://github.com/FFmpeg/FFmpeg.git
IJK_FFMPEG_FORK=https://github.com/FFmpeg/FFmpeg.git
IJK_FFMPEG_COMMIT=$2
IJK_FFMPEG_LOCAL_REPO=build/extra/ffmpeg

IJK_GASP_UPSTREAM=https://github.com/libav/gas-preprocessor.git
IJK_GASP_LOCAL_REPO=build/extra/gas-preprocessor

set -e

FF_ALL_ARCHS=
FF_ALL_ARCHS_IOS="armv7 arm64 i386 x86_64"
FF_ALL_ARCHS_TVOS="arm64 x86_64"
FF_ALL_ARCHS_MACOS="x86_64"

FF_PLATFORM=$1

function pull_common() {
    echo "== pull gas-preprocessor base =="
    sh scripts/pull-repo-base.sh $IJK_GASP_UPSTREAM $IJK_GASP_LOCAL_REPO

    echo "== pull ffmpeg base =="
    sh scripts/pull-repo-base.sh $IJK_FFMPEG_UPSTREAM $IJK_FFMPEG_LOCAL_REPO
}

function pull_fork() {
    echo "== pull ffmpeg fork $1 =="
    sh scripts/pull-repo-ref.sh $IJK_FFMPEG_FORK build/source/$FF_PLATFORM/ffmpeg-$1 ${IJK_FFMPEG_LOCAL_REPO}
    cd build/source/$FF_PLATFORM/ffmpeg-$1
    git checkout ${IJK_FFMPEG_COMMIT} -B SGPlayer
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

