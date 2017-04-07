#!/bin/bash

do_clean_framework_SGPlatform () {
  echo "clean SGPlatform..."
  if [ -d ".git" ]; then
    echo "remove SGPlatform from git submodule."
    git submodule deinit --all
  fi

  if [ -d "Vendors/SGPlatform/SGPlatform.xcodeproj" ]; then
    echo "remove SGPlatform files."
    rm -rf Vendors/SGPlatform
  fi
  echo "clean SGPlatform done."
}

do_clean_lib_ffmpeg () {
  echo "clean lib ffmpeg..."
  if [ -d "SGPlayer/Classes/Core/SGFFPlayer/ffmpeg/lib-iOS" ]; then
    echo "remove lib ffmpeg for iOS"
    rm -rf SGPlayer/Classes/Core/SGFFPlayer/ffmpeg/lib-iOS
  fi
  if [ -d "SGPlayer/Classes/Core/SGFFPlayer/ffmpeg/lib-macOS" ]; then
    echo "remove lib ffmpeg for macOS"
    rm -rf SGPlayer/Classes/Core/SGFFPlayer/ffmpeg/lib-macOS
  fi
  if [ -d "SGPlayer/Classes/Core/SGFFPlayer/ffmpeg/lib-tvOS" ]; then
    echo "remove lib ffmpeg for tvOS"
    rm -rf SGPlayer/Classes/Core/SGFFPlayer/ffmpeg/lib-tvOS
  fi
  echo "clean lib ffmpeg done."
}

do_clean_framework_SGPlatform
do_clean_lib_ffmpeg
