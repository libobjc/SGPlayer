![Logo](https://github.com/libobjc/SGPlayer/blob/master/documents/banner.jpg?raw=true)


![Build Status](https://img.shields.io/badge/build-%20passing%20-brightgreen.svg)
![Platform](https://img.shields.io/badge/Platform-%20iOS%20macOS%20tvOS%20-blue.svg)

# SGPlayer 

- SGPlayer is a powerful media play framework for iOS, macOS, and tvOS.

## Based On

- FFmpeg
- Metal
- AudioUnit

## Features

- iOS, tvOS, macOS.
- 360° panorama video.
- Background playback.
- RTMP/RTSP streaming.
- Setting playback speed.
- Multiple audio/video tracks.
- H.264/H.265 hardware accelerator.

## Build

```obj-c
git clone https://github.com/libobjc/SGPlayer.git
cd SGPlayer
git checkout 2.0.1 -B latest

// iOS
./build.sh iOS build

// tvOS
./build.sh tvOS build

// macOS
./build.sh macOS build
```

## Usage

- Open demo/demo.xcworkspace with Xcode.

## Dependencies

```obj-c
- SGPlayer.framework
- AVFoundation.framework
- AudioToolBox.framework
- VideoToolBox.framework
- libiconv.tbd
- libbz2.tbd
- libz.tbd
```

## Flow Chart

![Flow Chart](https://github.com/libobjc/SGPlayer/blob/master/documents/flow-chart.jpg?raw=true)

## Related

- [KTVHTTPCache](https://github.com/ChangbaDevs/KTVHTTPCache) - A smart media cache framework.
- [KTVVideoProcess](https://github.com/ChangbaDevs/KTVVideoProcess) - A High-Performance video effects processing framework.

## Communication

- GitHub : [Single](https://github.com/libobjc)
- Email : libobjc@gmail.com
