#!/bin/bash

ARGV1=$1

ROOT_PATH=`pwd`
LIB_FFMPEG_DOWNLOAD_URL=""
LIB_FFMPEG_FILE_NAME=""
LIB_FFMPEG_FILE_NAME_IOS="lib-iOS"
LIB_FFMPEG_FILE_NAME_MACOS="lib-macOS"
LIB_FFMPEG_FILE_NAME_TVOS="lib-tvOS"

do_lib_ffmpeg () {
  LIB_FFMPEG_DOWNLOAD_URL="http://omw595ki7.bkt.clouddn.com/ffmpeg/$LIB_FFMPEG_FILE_NAME.zip"
  echo "download lib ffmpeg..."
  curl -o $ROOT_PATH/$LIB_FFMPEG_FILE_NAME.zip $LIB_FFMPEG_DOWNLOAD_URL
  echo "unzip lib ffmpeg..."
  unzip $ROOT_PATH/$LIB_FFMPEG_FILE_NAME.zip -d $ROOT_PATH/SGPlayer/Classes/Core/SGFFPlayer/ffmpeg/
  echo "clean build file..."
  rm -rf $ROOT_PATH/$LIB_FFMPEG_FILE_NAME.zip
  echo "build done"
}

if [ "$ARGV1" == "iOS" ]; then
  echo "build for iOS"
  LIB_FFMPEG_FILE_NAME=$LIB_FFMPEG_FILE_NAME_IOS
  do_lib_ffmpeg
elif [ "$ARGV1" == "macOS" ]; then
  echo "build for macOS"
  LIB_FFMPEG_FILE_NAME=$LIB_FFMPEG_FILE_NAME_MACOS
  do_lib_ffmpeg
elif [ "$ARGV1" == "tvOS" ]; then
  echo "build for tvOS"
  LIB_FFMPEG_FILE_NAME=$LIB_FFMPEG_FILE_NAME_TVOS
  do_lib_ffmpeg
else
  echo echo "Usage:"
  echo "  build.sh iOS"
  echo "  build.sh macOS"
  echo "  build.sh tvOS"
  exit 1
fi
