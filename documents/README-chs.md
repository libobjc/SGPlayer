![(banner)](https://coding.net/u/0x010101/p/resource-public/git/raw/master/SGPlayer/banner-small.png)

![Build Status](https://img.shields.io/badge/build-%20passing%20-brightgreen.svg)
![Platform](https://img.shields.io/badge/Platform-%20iOS%20macOS%20tvOS%20-blue.svg)
![Support](https://img.shields.io/badge/support-%20VR%20360%C2%B0%20-orange.svg)

[English README](https://github.com/libobjc/SGPlayer/blob/master/README.md) | [原理详解](https://github.com/libobjc/SGPlayer/blob/master/documents/Principle-chs.md) | [视频下载](https://github.com/libobjc/SGDownload)

# SGPlayer 

- SGPlayer 是一款基于 AVPlayer、FFmpeg 的媒体资源播放器框架。支持360°全景视频，VR视频，RTMP、RTSP 等直播流；同时支持 iOS、macOS、tvOS 三个平台。

## 功能特点

- 支持播放360°全景视频。
- 支持手势、传感器操控360°全景视频。
- 支持双眼模式，具有畸变校正、色散校正。
- 支持 iOS、macOS、tvOS。
- 支持 H.264 硬件解码（VideoToolBox）。
- 支持 RTMP、RTSP 等直播流。
- 支持后台播放。
- 支持选择音频轨道。
- 支持控制音频输出音量。
- 支持无损视频截图。
- 支持近所有常用媒体格式。
- 支持 Bitcode。
- 极简的事件通知机制。

## 编译方式（2选1即可）

### 1.脚本编译

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

### 2.手动编译

- 步骤1 - 克隆项目并安装子模块

```
git clone git@github.com:libobjc/SGPlayer.git
cd SGPlayer
git submodule update --init --recursive

```

- 步骤2 - 手动编译 FFmpeg 并放在指定目录下

```obj-c

// 将FFmpeg编译出的.a静态库分别放在对应目录
/SGPlayer/Classes/Core/SGFFPlayer/ffmpeg/lib-iOS        // iOS
/SGPlayer/Classes/Core/SGFFPlayer/ffmpeg/lib-macOS      // macOS
/SGPlayer/Classes/Core/SGFFPlayer/ffmpeg/lib-tvOS       // tvOS

```

### 编译完成效果（仅目标平台的静态库存在即可）

![ffmpeg-libs](https://coding.net/u/0x010101/p/resource-public/git/raw/master/SGPlayer/ffmpeg-libs.jpg)


## 使用示例

- 详细使用示例参见 demo

#### iOS依赖

- SGPlayer.framework
- SGPlatform.framework  Optional
- CoreMedia.framework
- AudioToolBox.framework
- VideoToolBox.framework
- libiconv.tbd
- libbz2.tbd
- libz.tbd

#### macOS依赖

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

### 基础视屏播放

```obj-c

self.player = [SGPlayer player];

// 注册事件通知
[self.player registerPlayerNotificationTarget:self stateAction:@selector(stateAction:) progressAction:@selector(progressAction:) playableAction:@selector(playableAction:) errorAction:@selector(errorAction:)];

// 视频画面点击事件
[self.player setViewTapAction:^(SGPlayer * _Nonnull player, SGPLFView * _Nonnull view) {
    NSLog(@"player display view did click!");
}];

// 播放普通视频 （2种方式2选1即可）
[self.player replaceVideoWithURL:contentURL]; // 方式1
[self.player replaceVideoWithURL:contentURL videoType:SGVideoTypeNormal]; // 方式2

// 播放360度全景视频、VR视频
[self.player replaceVideoWithURL:contentURL videoType:SGVideoTypeVR];

// 播放
[self.player play];

```

### 高级设置


```obj-c

// 三种预设播放内核选择策略
self.player.decoder = [SGPlayerDecoder defaultDecoder];     // 默认配置，混合使用 AVPlayer和FFmpeg，根据容器格式动态选择播放内核
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


## 效果演示

### iOS

- 普通视频

![ios-i-see-fire](https://coding.net/u/0x010101/p/resource-public/git/raw/master/SGPlayer/ios-i-see-fire.gif)

- 360度全景视频

![ios-google-vr](https://coding.net/u/0x010101/p/resource-public/git/raw/master/SGPlayer/ios-google-vr.gif)

- 360度全景视频双眼模式

![ios-google-vr-box](https://coding.net/u/0x010101/p/resource-public/git/raw/master/SGPlayer/ios-google-vr-box.gif)


### macOS

- 普通视频

![mac-i-see-fire](https://coding.net/u/0x010101/p/resource-public/git/raw/master/SGPlayer/mac-google-vr.gif)

- VR全景视频

![mac-google-vr](https://coding.net/u/0x010101/p/resource-public/git/raw/master/SGPlayer/mac-google-vr.gif)



## 联系方式

- Email : libobjc@gmail.com
- Twitter : CoderSingle
- Weibo : 程序员Single
- QQ Group : 616349536
