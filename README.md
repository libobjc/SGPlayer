![(banner)](https://github.com/libobjc/resource/blob/master/SGPlayer/banner-small.png?raw=true)

![Build Status](https://img.shields.io/badge/build-%20passing%20-brightgreen.svg)
![Platform](https://img.shields.io/badge/Platform-%20iOS%20macOS%20tvOS%20-blue.svg)
![Support](https://img.shields.io/badge/support-%20VR%20360%C2%B0%20-orange.svg)

[中文介绍](https://github.com/libobjc/SGPlayer/blob/master/documents/README-chs.md) | [Principle](https://github.com/libobjc/SGPlayer/blob/master/documents/Principle-chs.md)

# SGPlayer 

- SGPlayer is a powerful media player framework for iOS, macOS, and tvOS. based on AVPlayer and FFmpeg. Support 360° panorama video, VR video. RTMP streaming.

## Features

- 360° panorama video.
- Gestures and sensors control vr video.
- distortion correction in cardboard mode.
- Support iOS, macOS, and tvOS.
- H.264 hardware accelerator (VideoToolBox).
- RTMP, RTSP streamings.
- Background playback mode.
- Selected audio track.
- Adjust the volume.
- Capture video artwork.
- Bitcode support.
- Simplest callback handle.

## Build Instructions (Choose one of the way)

### Method 1. Using build script

```obj-c

// iOS
git clone https://github.com/libobjc/SGPlayer.git
cd SGPlayer
sh compile-build.sh iOS

// macOS
git clone https://github.com/libobjc/SGPlayer.git
cd SGPlayer
sh compile-build.sh macOS

// tvOS
git clone https://github.com/libobjc/SGPlayer.git
cd SGPlayer
sh compile-build.sh tvOS

```

### Method 2. Manually build

- Step 1 - clone and init submodule.

```
git clone git@github.com:libobjc/SGPlayer.git
cd SGPlayer
git submodule update --init --recursive

```

- Step 2 - build FFmpeg and add libs to the corresponding directory.

```obj-c

/SGPlayer/Classes/Core/SGFFPlayer/ffmpeg/lib-iOS        // iOS
/SGPlayer/Classes/Core/SGFFPlayer/ffmpeg/lib-macOS      // macOS
/SGPlayer/Classes/Core/SGFFPlayer/ffmpeg/lib-tvOS       // tvOS

```

### check build results

![ffmpeg-libs](https://github.com/libobjc/resource/blob/master/SGPlayer/ffmpeg-libs.jpg?raw=true)


## Usage

- more examples in the demo applications.

#### Dependencies

```obj-c

// iOS
- SGPlayer.framework
- SGPlatform.framework  Optional
- CoreMedia.framework
- AudioToolBox.framework
- VideoToolBox.framework
- libiconv.tbd
- libbz2.tbd
- libz.tbd

// macOS
- SGPlayer.framework
- SGPlatform.framework  Optional
- CoreMedia.framework
- AudioToolBox.framework
- VideoToolBox.framework
- VideoDecodeAcceleration.framework
- libiconv.tbd
- libbz2.tbd
- libz.tbd
- libizma.tbd

```

### Basic video playback

```obj-c

self.player = [SGPlayer player];

// register callback handle.
[self.player registerPlayerNotificationTarget:self stateAction:@selector(stateAction:) progressAction:@selector(progressAction:) playableAction:@selector(playableAction:) errorAction:@selector(errorAction:)];

// display view tap action.
[self.player setViewTapAction:^(SGPlayer * _Nonnull player, SGPLFView * _Nonnull view) {
NSLog(@"player display view did click!");
}];

// playback plane video.
[self.player replaceVideoWithURL:contentURL]; // 方式1
[self.player replaceVideoWithURL:contentURL videoType:SGVideoTypeNormal]; // 方式2

// playback 360° panorama video.
[self.player replaceVideoWithURL:contentURL videoType:SGVideoTypeVR];

// start playing
[self.player play];

```

### Advanced settings


```obj-c

// 三种预设播放内核选择策略
self.player.decoder = [SGPlayerDecoder defaultDecoder];     // 默认配置，混合使用 AVPlayer和FFmpeg，根据容器格式动态选择播放内核
self.player.decoder = [SGPlayerDecoder AVPlayerDecoder];    // 仅使用 AVPlayer
self.player.decoder = [SGPlayerDecoder FFmpegDecoder];      // 仅使用 FFmpeg

// 单个容器格式单独配置示例
self.player.decoder.decodeTypeForMPEG4 = SGDecoderTypeFFmpeg;      // 使用 FFmpeg 播放 mp4 文件

// 开启 FFmpeg 硬解
self.player.decoder.hardwareAccelerateEnableForFFmpeg = YES;

// 进入 VR眼镜 模式
self.player.displayMode = SGDisplayModeBox;

// 设置后台播放模式
// 如果需要后台播放，需将项目的 Background Modes 打开并勾选 Audio 选项， 并将 AVAudioSession 的 Category 设为AVAudioSessionCategoryPlayback
self.player.backgroundMode = SGPlayerBackgroundModeAutoPlayAndPause;  // 自动暂停及恢复
self.player.backgroundMode = SGPlayerBackgroundModeContinue;          // 继续播放

```


## Screenshots

### iOS

- Plane video

![ios-i-see-fire](https://github.com/libobjc/resource/blob/master/SGPlayer/ios-i-see-fire.gif?raw=true)

- 360° panorama video

![ios-google-vr](https://github.com/libobjc/resource/blob/master/SGPlayer/ios-google-vr.gif?raw=true)

- Cardboard mode

![ios-google-vr-box](https://github.com/libobjc/resource/blob/master/SGPlayer/ios-google-vr-box.gif?raw=true)


### macOS

- Plane video

![mac-i-see-fire](https://github.com/libobjc/resource/blob/master/SGPlayer/mac-i-see-fire.gif?raw=true)

- 360° panorama video

![mac-google-vr](https://github.com/libobjc/resource/blob/master/SGPlayer/mac-google-vr.gif?raw=true)



## Communication

- Sina Weibo : 程序员Single
- Email : musicman_leehom@126.com
- QQ Group : 616349536
