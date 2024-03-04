#!/bin/sh

set -e

PLATFORM=$1
ACTION=$2

FFMPEG_VERSION=n4.4.4
OPENSSL_VERSION=OpenSSL_1_1_1w

if [ "$ACTION" = "build" ]; then
    sh scripts/init-openssl.sh $PLATFORM $OPENSSL_VERSION
    sh scripts/init-ffmpeg.sh  $PLATFORM $FFMPEG_VERSION
    sh scripts/compile-openssl.sh $PLATFORM "build"
    sh scripts/compile-ffmpeg.sh $PLATFORM "build"
elif [ "$ACTION" = "clean" ]; then
    sh scripts/compile-openssl.sh $PLATFORM "clean"
    sh scripts/compile-ffmpeg.sh $PLATFORM "clean"
else
    echo "Usage:"
    echo "  sh build.sh iOS build"
    echo "  sh build.sh iOS clean"
    echo " ---"
    echo "  sh build.sh tvOS build"
    echo "  sh build.sh tvOS clean"
    echo " ---"
    echo "  sh build.sh macOS build"
    echo "  sh build.sh macOS clean"
    exit 1
fi
