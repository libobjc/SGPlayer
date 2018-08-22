#!/bin/bash

do_clean_ffmpeg () {
  echo "clean ffmpeg..."
  cd SGPlayer/Classes/Core/SGFFmpeg/
  rm -rf -v `find . -name "FFmpeg-*"`
  rm -rf -v `find . -name "__MACOSX"`
  echo "clean ffmpeg done."
}

do_clean_ffmpeg
