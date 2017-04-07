![(banner)](https://coding.net/u/0x010101/p/resource-public/git/raw/master/SGPlayer/banner-small.png)

![Build Status](https://img.shields.io/badge/build-%20passing%20-brightgreen.svg)
![Platform](https://img.shields.io/badge/Platform-%20iOS%20macOS%20tvOS%20-blue.svg)
![Support](https://img.shields.io/badge/support-%20VR%20360%C2%B0%20-orange.svg)

# SGPlayer 

- SGPlayer是一个强大的媒体资源播放器框架，内核由AVPlayer、FFmpeg组成，通过播放内核选择策略动态选择最优播放内核，并可以自定义内核选择策略。

## 功能特点

- 支持VR全景视频播放
- 支持手势、传感器操控VR全景视频
- 支持VR眼镜双眼模式，并具有边缘畸变校正功能
- 支持iOS、macOS、tvOS
- 支持H.264硬解解码(VideoToolBox)
- 支持选择软件解码、硬件解码
- 支持RTMP、RTSP等直播流
- 支持所有常见媒体格式
- 支持选择视频图像缩放方式
- 支持选择音频轨道
- 支持后台播放
- 支持调整音频输出音量
- 支持无损视频截图
- 支持Bitcode
- 极简的事件通知机制

## 编译方式（2选1即可）

### 1.脚本编译

```obj-c

// iOS
git clone https://github.com/libobjc/SGPlayer.git
cd SGPlayer
sh build.sh iOS

// macOS
git clone https://github.com/libobjc/SGPlayer.git
cd SGPlayer
sh build.sh macOS

// tvOS
git clone https://github.com/libobjc/SGPlayer.git
cd SGPlayer
sh build.sh tvOS

```

### 2.手动编译

- 步骤1 - 克隆项目并安装子模块

```
git clone git@github.com:libobjc/SGPlayer.git
cd SGPlayer
git submodule update --init --recursive

```

- 步骤2 - 手动编译FFmpeg并放在指定目录下

```obj-c

// 将FFmpeg编译出的.a静态库分别放在对应目录
/SGPlayer/Classes/Core/SGFFPlayer/ffmpeg/lib-iOS        // iOS
/SGPlayer/Classes/Core/SGFFPlayer/ffmpeg/lib-macOS      // macOS
/SGPlayer/Classes/Core/SGFFPlayer/ffmpeg/lib-tvOS       // tvOS

```

### 编译完成效果(仅目标平台的静态库存在即可)

![ffmpeg-libs](https://coding.net/u/0x010101/p/resource-public/git/raw/master/SGPlayer/ffmpeg-libs.png)


## 使用示例

- 详细使用示例参见demo

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

// 播放VR全景视频
[self.player replaceVideoWithURL:contentURL videoType:SGVideoTypeVR];

// 播放
[self.player play];

```

### 高级设置


```obj-c

// 三种预设播放内核选择策略
self.player.decoder = [SGPlayerDecoder defaultDecoder];     // 默认配置，混合使用AVPlayer和FFmpeg，根据容器格式动态选择播放内核
self.player.decoder = [SGPlayerDecoder AVPlayerDecoder];    // 仅使用AVPlayer
self.player.decoder = [SGPlayerDecoder FFmpegDecoder];      // 仅使用FFmpeg

// 单个容器格式单独配置示例
self.player.decoder.mpeg4Format = SGDecoderTypeFFmpeg;      // 使用FFmpeg播放mp4文件

// 开启FFmpeg硬解
self.player.decoder.ffmpegHardwareDecoderEnable = YES;

// 进入VR眼镜模式
self.player.displayMode = SGDisplayModeBox;

// 设置后台播放模式
// 如果需要后台播放，需将项目的Background Modes打开并勾选Audio选项， 并将AVAudioSession的Category设为AVAudioSessionCategoryPlayback
self.player.backgroundMode = SGPlayerBackgroundModeAutoPlayAndPause;  // 自动暂停及恢复
self.player.backgroundMode = SGPlayerBackgroundModeContinue;          // 继续播放

```


## 效果演示

### iOS

- 普通视频

![ios-i-see-fire](https://coding.net/u/0x010101/p/resource-public/git/raw/master/SGPlayer/ios-i-see-fire.gif)

- VR全景视频

![ios-google-vr](https://coding.net/u/0x010101/p/resource-public/git/raw/master/SGPlayer/ios-google-vr.gif)

- VR全景视频双眼模式

![ios-google-vr-box](https://coding.net/u/0x010101/p/resource-public/git/raw/master/SGPlayer/ios-google-vr-box.gif)


### macOS

- 普通视频

![mac-i-see-fire](https://coding.net/u/0x010101/p/resource-public/git/raw/master/SGPlayer/mac-google-vr.gif)

- VR全景视频

![mac-google-vr](https://coding.net/u/0x010101/p/resource-public/git/raw/master/SGPlayer/mac-google-vr.gif)



## 联系方式

- Sina Weibo : 程序员Single
- Email : musicman_leehom@126.com
- QQ交流群 : 616349536
