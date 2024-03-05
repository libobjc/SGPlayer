![Logo](https://github.com/libobjc/SGPlayer/blob/master/documents/banner.jpg?raw=true)


![Build Status](https://img.shields.io/badge/build-%20passing%20-brightgreen)  ![License](https://img.shields.io/badge/license-MIT-red) ![Platform](https://img.shields.io/badge/Platform-%20iOS%20macOS%20tvOS%20-blue)

# SGPlayer 

- SGPlayer is a powerful media play framework for iOS, macOS, and tvOS.

## Features

- iOS, tvOS, macOS.
- 360° panorama video.
- Compose complex asset.
- Background playback.
- RTMP/RTSP streaming.
- Setting playback speed.
- Multiple audio/video tracks.
- H.264/H.265 hardware accelerator.
- Accurate status notifications.
- Thread safety.

## Based On

- FFmpeg
- Metal
- AudioToolbox

## Requirements

- iOS 13.0 or later
- tvOS 13.0 or later
- macOS 10.15 or later

## Getting Started

#### Build FFmpeg and OpenSSL 

- Build scripts are used by default for FFmpeg 4.4.4 and OpenSSL 1.1.1w

```obj-c
git clone https://github.com/libobjc/SGPlayer.git
cd SGPlayer
git checkout 2.1.0 -B latest

// iOS
./build.sh iOS build

// tvOS
./build.sh tvOS build

// macOS
./build.sh macOS build
```

#### Open demo project in Xcode

- Open demo/demo.xcworkspace. You can see simple use cases.

#### Check Dependencies

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

## Author

- GitHub : [Single](https://github.com/libobjc)
- Email : libobjc@gmail.com

## Developed by Author

- [KTVHTTPCache](https://github.com/ChangbaDevs/KTVHTTPCache) - A smart media cache framework.
- [KTVVideoProcess](https://github.com/ChangbaDevs/KTVVideoProcess) - A High-Performance video effects processing framework.
