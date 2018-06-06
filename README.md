![(Logo)](http://oxl6mxy2t.bkt.clouddn.com/SGPlayer/banner-small.png)

![Build Status](https://img.shields.io/badge/build-%20passing%20-brightgreen.svg)
![Platform](https://img.shields.io/badge/Platform-%20iOS%20macOS%20tvOS%20-blue.svg)
![Support](https://img.shields.io/badge/support-%20VR%20360%C2%B0%20-orange.svg)

[中文介绍](https://github.com/libobjc/SGPlayer/blob/master/documents/README-chs.md) | [Principle（原理详解）](https://github.com/libobjc/SGPlayer/blob/master/documents/Principle-chs.md) | [Video Download（视频下载）](https://github.com/libobjc/SGDownload) | [Android Version (XLPlayer) ](https://github.com/xl-player-developers/xl_player)

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
git clone https://github.com/libobjc/SGPlayer.git
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

![ffmpeg-libs](http://oxl6mxy2t.bkt.clouddn.com/SGPlayer/ffmpeg-libs.png)


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

// selected playback core.
self.player.decoder = [SGPlayerDecoder defaultDecoder];     // default config，Together with AVPlayer and FFmpeg.
self.player.decoder = [SGPlayerDecoder AVPlayerDecoder];    // only use AVPlayer
self.player.decoder = [SGPlayerDecoder FFmpegDecoder];      // only use FFmpeg

// set the specified format playback core.
self.player.decoder.decodeTypeForMPEG4 = SGDecoderTypeFFmpeg;      // use FFmoeg play mp4 files.

// open FFmpeg hardware accelerate.
self.player.decoder.hardwareAccelerateEnableForFFmpeg = YES;

// enter cardboard mode
self.player.displayMode = SGDisplayModeBox;

// set background mode.
// if allow background mode, you should open 'Background Modes' and check 'Audio' option， and set AVAudioSession Category to AVAudioSessionCategoryPlayback
self.player.backgroundMode = SGPlayerBackgroundModeAutoPlayAndPause;  // auto play and pause.
self.player.backgroundMode = SGPlayerBackgroundModeContinue;          // continue.

```


## Screenshots

### iOS

- Plane video

![ios-i-see-fire](http://oxl6mxy2t.bkt.clouddn.com/SGPlayer/ios-i-see-fire.gif)

- 360° panorama video

![ios-google-vr](http://oxl6mxy2t.bkt.clouddn.com/SGPlayer/ios-google-vr.gif)

- Cardboard mode

![ios-google-vr-box](http://oxl6mxy2t.bkt.clouddn.com/SGPlayer/ios-google-vr-box.gif)


### macOS

- Plane video

![mac-i-see-fire](http://oxl6mxy2t.bkt.clouddn.com/SGPlayer/mac-i-see-fire.gif)

- 360° panorama video

![mac-google-vr](http://oxl6mxy2t.bkt.clouddn.com/SGPlayer/mac-google-vr.gif)



## Communication

- GitHub : [Single](https://github.com/libobjc)
- Email : libobjc@gmail.com
- Twitter : CoderSingle
- Weibo : 程序员Single
- QQ Group : 616349536


## Developed by Single

- [KTVHTTPCache](https://github.com/ChangbaDevs/KTVHTTPCache) - A smart media cache framework.
- [KTVVideoProcess](https://github.com/ChangbaDevs/KTVVideoProcess) - A High-Performance video effects processing framework.
