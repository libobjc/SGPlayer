//
//  SGPlayer.m
//  SGPlayer
//
//  Created by Single on 16/6/28.
//  Copyright © 2016年 single. All rights reserved.
//

#import "SGPlayerImp.h"
#import "SGMacro.h"
//#import "SGPlayerNotification.h"
#import "SGDisplayView.h"
//#import "SGAVPlayer.h"
#import "SGPlayer.h"

#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
#import "SGAudioManager.h"
#endif

@interface SGPlayer2 ()

//@property (nonatomic, copy) NSURL * contentURL;
//@property (nonatomic, assign) SGVideoType videoType;
//
//@property (nonatomic, strong) SGDisplayView * displayView;
//@property (nonatomic, assign) SGDecoderType decoderType;
//@property (nonatomic, strong) SGFFPlayer * ffPlayer;
//
//@property (nonatomic, assign) BOOL needAutoPlay;
//@property (nonatomic, assign) NSTimeInterval lastForegroundTimeInterval;

@end

@implementation SGPlayer2

//+ (instancetype)player
//{
//    return [[self alloc] init];
//}
//
//- (instancetype)init
//{
//    if (self = [super init]) {
//        self.decoder = [SGPlayerDecoder decoderByDefault];
//        self.contentURL = nil;
//        self.videoType = SGVideoTypeNormal;
////        self.backgroundMode = SGBackgroundModeAutoPlayAndPause;
//        self.displayMode = SGDisplayModePlane;
//        self.viewGravityMode = SGGravityModeResizeAspect;
//        self.playableBufferInterval = 2.f;
//        self.viewAnimationHidden = YES;
//        self.volume = 1;
////        self.displayView = [SGDisplayView displayViewWithAbstractPlayer:self];
//    }
//    return self;
//}
//
//- (void)replaceVideoWithURL:(nullable NSURL *)contentURL
//{
//    [self replaceVideoWithURL:contentURL videoType:SGVideoTypeNormal];
//}
//
//- (void)replaceVideoWithURL:(nullable NSURL *)contentURL videoType:(SGVideoType)videoType
//{
//    self.error = nil;
//    self.contentURL = contentURL;
//    self.decoderType = [self.decoder decoderTypeForContentURL:self.contentURL];
//    self.videoType = videoType;
//    switch (self.videoType)
//    {
//        case SGVideoTypeNormal:
//        case SGVideoTypeVR:
//            break;
//        default:
//            self.videoType = SGVideoTypeNormal;
//            break;
//    }
//    if (!self.ffPlayer) {
////        self.ffPlayer = [SGFFPlayer playerWithAbstractPlayer:self];
//    }
////    [self.ffPlayer replaceVideo];
//}
//
//- (void)play
//{
//#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
//    [UIApplication sharedApplication].idleTimerDisabled = YES;
//#endif
//    [self.ffPlayer play];
//}
//
//- (void)pause
//{
//#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
//    [UIApplication sharedApplication].idleTimerDisabled = NO;
//#endif
//    [self.ffPlayer pause];
//}
//
//- (void)stop
//{
//#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
//    [UIApplication sharedApplication].idleTimerDisabled = NO;
//#endif
//    
//    [self replaceVideoWithURL:nil];
//}
//
////- (BOOL)seekEnable
////{
////    return self.ffPlayer.seekEnable;
////}
////
////- (BOOL)seeking
////{
////    return self.ffPlayer.seeking;
////}
////
//- (void)seekToTime:(NSTimeInterval)time
//{
////    [self seekToTime:time completeHandler:nil];
//}
////
//- (void)seekToTime:(NSTimeInterval)time completeHandler:(nullable void (^)(BOOL))completeHandler
//{
////    [self.ffPlayer seekToTime:time completeHandler:completeHandler];
//}
////
////- (void)setVolume:(CGFloat)volume
////{
////    _volume = volume;
////    [self.ffPlayer reloadVolume];
////}
////
////- (void)setPlayableBufferInterval:(NSTimeInterval)playableBufferInterval
////{
////    _playableBufferInterval = playableBufferInterval;
////    [self.ffPlayer reloadPlayableBufferInterval];
////}
//
//- (void)setViewGravityMode:(SGGravityMode)viewGravityMode
//{
//    _viewGravityMode = viewGravityMode;
////    [self.displayView reloadGravityMode];
//}
//
////- (SGPlayerState)state
////{
////    return self.ffPlayer.state;
////}
////
////- (CGSize)presentationSize
////{
////    return self.ffPlayer.presentationSize;
////}
//
////- (NSTimeInterval)bitrate
////{
////    return self.ffPlayer.bitrate;
////}
////
////- (NSTimeInterval)progress
////{
////    return self.ffPlayer.progress;
////}
////
////- (NSTimeInterval)duration
////{
////    return self.ffPlayer.duration;
////}
////
////- (NSTimeInterval)playableTime
////{
////    return self.ffPlayer.playableTime;
////}
//
//- (SGPLFImage *)snapshot
//{
////    return self.displayView.snapshot;
//    return nil;
//}
//
//- (SGPLFView *)view
//{
//    return self.displayView;
//}
//
//- (void)setError:(SGError * _Nullable)error
//{
//    if (self.error != error) {
//        self->_error = error;
//    }
//}
//
//- (void)cleanPlayer
//{
//    [self.ffPlayer stop];
//    self.ffPlayer = nil;
//    
//    [self cleanPlayerView];
//    
//#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
//    [UIApplication sharedApplication].idleTimerDisabled = NO;
//#endif
//    
//    self.needAutoPlay = NO;
//    self.error = nil;
//}
//
//- (void)cleanPlayerView
//{
//    [self.view.subviews enumerateObjectsUsingBlock:^(__kindof SGPLFView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        [obj removeFromSuperview];
//    }];
//}
//
//- (void)dealloc
//{
//    SGPlayerLog(@"SGPlayer release");
//    [self cleanPlayer];
//
//#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
////    [[NSNotificationCenter defaultCenter] removeObserver:self];
////    [[SGAudioManager manager] removeHandlerTarget:self];
//#endif
//}

@end
