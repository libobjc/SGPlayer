#!/bin/bash

ARGV1=$1

ROOT_PATH=`pwd`
FFMPEG_VERSION="4.0.2"
FFMPEG_PATH=$ROOT_PATH/SGPlayer/Classes/Core/SGFFmpeg/
FFMPEG_LIB_FILE_NAME=""
FFMPEG_LIB_FILE_NAME_IOS="FFmpeg-"$FFMPEG_VERSION"-lib-iOS"
FFMPEG_LIB_FILE_NAME_MACOS="FFmpeg-"$FFMPEG_VERSION"-lib-macOS"
FFMPEG_LIB_FILE_NAME_TVOS="FFmpeg-"$FFMPEG_VERSION"-lib-tvOS"
FFMPEG_INCLUDE_FILE_NAME="FFmpeg-"$FFMPEG_VERSION"-include"

do_ffmpeg_lib () {
  LIB_FFMPEG_FILE_PATH=$FFMPEG_PATH$FFMPEG_LIB_FILE_NAME
  if [ -d LIB_FFMPEG_FILE_PATH ]; then
    echo "ffmpeg lib exist."
  else
    FFMPEG_LIB_DOWNLOAD_URL="http://omw595ki7.bkt.clouddn.com/FFmpeg/$FFMPEG_LIB_FILE_NAME.zip"
    echo "download ffmpeg lib..."
    curl -o $LIB_FFMPEG_FILE_PATH.zip $FFMPEG_LIB_DOWNLOAD_URL
    echo "unzip ffmpeg lib..."
    unzip $LIB_FFMPEG_FILE_PATH.zip -d $FFMPEG_PATH
    echo "clean temp file..."
    rm -rf -v $LIB_FFMPEG_FILE_PATH.zip
    echo "download ffmpeg lib done."
  fi
}

do_ffmpeg_inlcude () {
  INCLUDE_FFMPEG_FILE_PATH=$FFMPEG_PATH$FFMPEG_INCLUDE_FILE_NAME
  if [ -d INCLUDE_FFMPEG_FILE_PATH ]; then
    echo "ffmpeg include exist."
  else
    INCLUDE_FFMPEG_DOWNLOAD_URL="http://omw595ki7.bkt.clouddn.com/FFmpeg/$FFMPEG_INCLUDE_FILE_NAME.zip"
    echo "download ffmpeg include..."
    curl -o $INCLUDE_FFMPEG_FILE_PATH.zip $INCLUDE_FFMPEG_DOWNLOAD_URL
    echo "unzip ffmpeg include..."
    unzip $INCLUDE_FFMPEG_FILE_PATH.zip -d $FFMPEG_PATH
    echo "clean temp file..."
    rm -rf -v $INCLUDE_FFMPEG_FILE_PATH.zip
    echo "download ffmpeg include done."
  fi
}

if [ "$ARGV1" == "iOS" ]; then
  echo "build for iOS."
  FFMPEG_LIB_FILE_NAME=$FFMPEG_LIB_FILE_NAME_IOS
  do_ffmpeg_inlcude
  do_ffmpeg_lib
  echo "build iOS done."
elif [ "$ARGV1" == "macOS" ]; then
  echo "build for macOS."
  FFMPEG_LIB_FILE_NAME=$FFMPEG_LIB_FILE_NAME_MACOS
  do_ffmpeg_inlcude
  do_ffmpeg_lib
  echo "build macOS done."
elif [ "$ARGV1" == "tvOS" ]; then
  echo "build for tvOS."
  FFMPEG_LIB_FILE_NAME=$FFMPEG_LIB_FILE_NAME_TVOS
  do_ffmpeg_inlcude
  do_ffmpeg_lib
  echo "build tvOS done."
else
  echo echo "Usage:"
  echo "  build.sh iOS"
  echo "  build.sh macOS"
  echo "  build.sh tvOS"
  exit 1
fi
