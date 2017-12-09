# SGPlayer 原理详解

SGPlayer 是一款基于 AVPlayer、FFmpeg 的媒体资源播放器框架。支持全景视频，RTMP、RTSP 等直播流；同时支持 iOS、macOS、tvOS 三个平台。本文将采用图解+说明的方式把关键模块的实现原理介绍给大家。

## 发起原因

关于视频播放，苹果提供的 AVPlayer 在性能上有着十分出色的表现，在无特需求且资源可控的时，首选一定是它。但随着 VR 和直播的兴起，仅使用 AVPlayer 很多时候已经无法满足需求。出于性能考虑，又不能完全抛弃 AVPlayer，毕竟在点播时有着明显的优势。而在现有的开源项目中，普遍定位比较单一，并不能兼顾 AVPlayer、直播、VR。这样一来，需同时使用3款播放器才能满足需求，即点播使用 AVPlayer，直播使用一个独立的播放器，VR 使用一个独立的播放器。这样处理3套不同的接口和回调事件，着实很让人崩溃！SGPlayer 的出现大大简化了这一过程。


## 组成结构 和 播放流程

![SGPlayer](http://oxl6mxy2t.bkt.clouddn.com/SGPlayer/SGFFPlayer-playback.jpeg)

上图展示了 SGPlayer 的播放流程和主要组件，下面简单介绍图中各组件的分工

### SGPlayer

SGPlayer是一个抽象的播放器外壳，它本身并不具备播放功能。仅作为和外界交互的载体。真正的播放由内部的 SGAVPlayer 和 SGFFPlayer 完成。而画面绘制由内部的 SGDisplayView 完成。

### SGPlayerDecoder

SGPlayerDecoder 是播放内核的选择器，根据资源类型动态选择使用 SGAVPlayer 或 SGFFPlayer 进行播放，可通过更改其配置参数，来自定义播放内核的选择策略。

### SGAVPlayer

SGAVPlayer 是基于 AVPlayer 封装而成，视频画面输出至 SGDsiplayView，并根据视频类型（全景或平面）进行展示。音频由系统处理无需额外操作。

### SGFFPlayer

SGFFPlayer 是基于 FFmpeg 封装而成，支持近所有的主流视频格式。视频画面同样输出至 SGDsiplayView。音频则输出至 SGAudioManager，再由 SGAudioManager 使用 Audio Unit 进行播放。

### SGDisplayView

SGDisplayView 负责视频画面的绘制。它本身不会绘制视频画面，仅作为绘制层的父视图使用，真正的绘制由内部的 AVPlayerLayer 和 SGGLViewController 完成，选择规则如下表所示。

|| 平面 | 全景
---|---|---
SGAVPlayer | AVPlayerLayer | SGGLViewController
SGFFPlayer | SGGLViewController | SGGLViewController

### SGAudioManager

SGAudioManager 负责声音的播放和音频事件的处理。内部使用 AUGraph 做了一层混音，通过混音可以设置声音的输出音量大小等操作。

### 小结

了解了各组件的功能，重新梳理一下完整的播放过程

- SGPlayer 收到播放请求。
- 由 SGPlayerDecoder 根据资源类型分发给 SGAVPlayer 或 SGFFPlayer 进行播放。
- 如果使用 SGAVPlayer 播放，根据视频类型将画面输出给 SGDisplayView 中的 AVPlayerLayer 或 SGGLViewController。
- 如果使用 SGFFPlayer 播放，将视频画面输出给 SGDisplayView，音频输出至 SGAudioManager。

通过抽象的 SGPlayer 将真正负责播放的 SGAVPlayer 和 SGFFPlayer 屏蔽起来，这样可以保证无论资源是何种类型，对外仅暴露一套统一的接口和回调，将播放内核间的差异内部消化，尽可能降低使用成本。


## 全景图像原理

全景图像与平面图像本质都是一张 2D 图片，区别在于展示时的载体。对于平面图而言，用于展示的模型是一个矩形，仅需将图像上的像素一一对应在矩形上即可；而全景图像展示的模型是一个球，需要将图像上的每一个像素都对应到球面相应位置上。在绘制流程上二者的差别并不大，仅在贴图规则和呈现方式上略有区别。

### 贴图规则

![image](http://oxl6mxy2t.bkt.clouddn.com/SGPlayer/vr-texture.jpeg)

把平面图片贴到球面上的过程和地球仪很相似。以上图为例，左侧图片中的每一个像素，都可以在右侧球面上找到对应的位置。下面列举一个关键的对应关系。

- 直线AB 上所有的点都与 点J 对应，同理 直线CD 上所有的点都与 点K 对应。
- 直线MN 上的点与 赤道 上的点一一对应。
- 直线AC/BD 上的点与绿 色经线前半面 上的点一一对应。
- 直线EF 上的点与 绿色经线后半面 上的点一一对应。

### 呈现方式

![ball](http://oxl6mxy2t.bkt.clouddn.com/SGPlayer/vr-ball.jpeg)

上图展示了全景图像的呈现方式，不同于平面，全景图像需将观景点放在球心，站在球心观看球面上的图像。最终将 曲面ABCD 在 平面ABCD 上的投影显示到屏幕上。

### 小结

这部分内容在实现上涉及到很多 OpenGL 的内容，需要具备一些 OpenGL 的基础。在双眼模式下还需要做 畸变校正 和 色散校正 来保证画面被真实的还原。具体实现可以查看 SGGLViewController。


## SGFFPlayer 运作流程

![SGFFPlayer](http://oxl6mxy2t.bkt.clouddn.com/SGPlayer/SGFFPlayer-thread.jpeg)

上图展示了 SGFFPlayer 的协作流程图，下面简单介绍图中各组件

### 线程模型

SGFFPlayer 中共有4个线程。与图中4个蓝色圆圈对应。

- 数据读取 - Read Packet Loop
- 视频解码 - Video Decode Loop
- 视频绘制 - Video Display Loop
- 音频播放 - Audio Playback Loop

图中隐藏掉了线程的控制条件。在4个线程的协作下完成整个播放过程。

### SGVideoDecoder

SGVideoDecoder 是视频解码器，初始化时可配置同步、异步解码，以及是否开启硬解。上图中采用的是异步解码，默认的解码线程对应关系如下表所示。

|| 平面 | 全景
---|---|---
软件解码 | 异步 | 同步
硬件解码 | 异步 | 异步

- 同步解码在收到视频包后立即解码，并存入视频帧队列。
- 异步解码在收到视频包后仅存入音频包队列，当独立的解码线程取出音频包并完成解码后，再存入视频帧队列。

### SGAudioDecoder

SGAudioDecoder 是音频解码器，采用同步解码，收到音频包后立即解码，并存入音频帧队列。

### 数据队列 SGFFPacketQueue、SGFFFrameQueue

- SGFFPacketQueue 是包队列，用于管理解码前的数据包（AVPacket）。
- SGFFFrameQueue 是帧队列，用于管理解码后的帧（SGFFVideoFrame 或 SGFFAudioFrame）。

它们都支持数据的同步获取和异步获取，同步获取是通过条件变量（NSCondition）实现。当队列中没有足够数据时，会阻塞当前线程，直到向队列中添加新元素时，线程才会被唤醒。

### 帧复用池 SGFFFramePool

该部分并没有在上图中体现，但能避免一些不必要的性能开销。由于音频帧和视频帧的数量很大，1分钟的视频就包含几千帧的数据。如果每一帧都新创建的话会造成不必要的资源浪费。通过 SGFFFramePool 创建的 SGFFFrame 在使用完成后不会立即释放，而是被复用池回收，以供下次使用，达到仅创建最小数量的帧对象的目的。

### 音视频同步

常用的同步当时有3种

1. 音频时钟
1. 视频时钟
1. 自制时钟

在 SGFFPlayer 中，优先使用音频时钟，当视频中没有音轨时，会使用视频时钟进行同步。

### 小结

了解了各组件的功能，以视频异步解码为例，重新梳理一下整个流程

- 数据读取线程读取到数据包，根据数据包类型分发给音频解码器或视频解码器。
- 如果为音频包，音频解码器收到音频包的同时进行解码，并将解码后的音频帧存入音频帧队列。
- 如果为视频包，由于视频解码器是异步解码，仅将视频包放入视频包队列，等待视频解码线程来队列中取视频包。
- 视频解码线程循环从视频包队列中取出视频包，同时解码，并将解码后的视频帧存入视频帧队列。
- 音频播放线程循环在音频帧队列中取出音频帧并播放。
- 视频展示线程循环在视频帧队列中取出视频帧并绘制。

到这里SGFFPlayer的运作流程已经很清晰了，只需在各个环节中加入对应的条件控制，就可以完成播放功能了。

## 总结

关于 SGPlayer 的原理就阐述到这里，由于本文以理论为主，所以并没有贴代码。感兴趣的同学可以在 [GitHub](https://github.com/libobjc/SGPlayer) 上找到全部的代码实现。希望对大家能有所帮助。
