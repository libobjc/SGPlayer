#!/bin/bash

ARGV1=$1

ROOT_PATH=`pwd`
LIB_FFMPEG_DOWNLOAD_URL=""
LIB_FFMPEG_FILE_NAME=""
LIB_FFMPEG_FILE_NAME_IOS="lib-iOS"
LIB_FFMPEG_FILE_NAME_MACOS="lib-macOS"
LIB_FFMPEG_FILE_NAME_TVOS="lib-tvOS"

do_lib_ffmpeg () {
  if [ -d $ROOT_PATH/SGPlayer/Classes/Core/SGFFPlayer/ffmpeg/$LIB_FFMPEG_FILE_NAME ]; then
    echo "lib ffmpeg exist."
  else
    LIB_FFMPEG_DOWNLOAD_URL="http://omw595ki7.bkt.clouddn.com/ffmpeg2/$LIB_FFMPEG_FILE_NAME.zip"
    echo "download lib ffmpeg..."
    curl -o $ROOT_PATH/$LIB_FFMPEG_FILE_NAME.zip $LIB_FFMPEG_DOWNLOAD_URL
    echo "unzip lib ffmpeg..."
    unzip $ROOT_PATH/$LIB_FFMPEG_FILE_NAME.zip -d $ROOT_PATH/SGPlayer/Classes/Core/SGFFPlayer/ffmpeg/
    echo "clean temp file..."
    rm -rf $ROOT_PATH/$LIB_FFMPEG_FILE_NAME.zip
    echo "download lib ffmpeg done."
  fi
}

do_framework_SGPlatform () {
  echo "check SGPlatform..."
  if [ -d ".git" ]; then
    git submodule update --init --recursive
  else
    echo "no git repository."
  fi
  if [ ! -d "Vendors/SGPlatform/SGPlatform.xcodeproj" ]; then
    echo "clone SGPlatform from GitHub..."
    git clone https://github.com/libobjc/SGPlatform.git Vendors/SGPlatform
    echo "SGPlatform done."
  else
    echo "SGPlatform done."
  fi
}

if [ "$ARGV1" == "iOS" ]; then
  echo "build for iOS."
  LIB_FFMPEG_FILE_NAME=$LIB_FFMPEG_FILE_NAME_IOS
  do_framework_SGPlatform
  do_lib_ffmpeg
  echo "build iOS done."
elif [ "$ARGV1" == "macOS" ]; then
  echo "build for macOS."
  LIB_FFMPEG_FILE_NAME=$LIB_FFMPEG_FILE_NAME_MACOS
  do_framework_SGPlatform
  do_lib_ffmpeg
  echo "build macOS done."
elif [ "$ARGV1" == "tvOS" ]; then
  echo "build for tvOS."
  LIB_FFMPEG_FILE_NAME=$LIB_FFMPEG_FILE_NAME_TVOS
  do_framework_SGPlatform
  do_lib_ffmpeg
  echo "build tvOS done."
else
  echo echo "Usage:"
  echo "  build.sh iOS"
  echo "  build.sh macOS"
  echo "  build.sh tvOS"
  exit 1
fi
