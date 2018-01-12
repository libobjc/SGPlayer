//
//  PlayerViewController.m
//  demo-ios
//
//  Created by Single on 2017/3/15.
//  Copyright © 2017年 single. All rights reserved.
//

#import "PlayerViewController.h"
//#import <SGPlayer/SGPlayer.h>
#import <SGAVPlayer/SGAVPlayer.h>

@interface PlayerViewController ()

@property (nonatomic, strong) SGAVPlayer * player;

@property (weak, nonatomic) IBOutlet UILabel *stateLabel;
@property (weak, nonatomic) IBOutlet UISlider *progressSilder;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalTimeLabel;

@property (nonatomic, assign) BOOL progressSilderTouching;

@end

@implementation PlayerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    self.player = [[SGAVPlayer alloc] init];
    [self sg_registerNotificationForPlayer:self.player
                       playbackStateAction:@selector(playbackStateAction:)
                           loadStateAction:@selector(loadStateAction:)
                        playbackTimeAction:@selector(playbackTimeAction:)
                              loadedAction:@selector(loadedTimeAction:)
                               errorAction:@selector(errorAction:)];
//    [self.player setViewTapAction:^(SGPlayer * _Nonnull player, SGPLFView * _Nonnull view) {
//        NSLog(@"player display view did click!");
//    }];
    [self.view insertSubview:self.player.view atIndex:0];
    
    static NSURL * normalVideo = nil;
    static NSURL * vrVideo = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        normalVideo = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"i-see-fire" ofType:@"mp4"]];
        vrVideo = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"google-help-vr" ofType:@"mp4"]];
    });
    [self.player replaceWithContentURL:normalVideo];
//    switch (self.demoType)
//    {
//        case DemoType_AVPlayer_Normal:
//            [self.player replaceVideoWithURL:normalVideo];
//            break;
//        case DemoType_AVPlayer_VR:
//            [self.player replaceVideoWithURL:vrVideo videoType:SGVideoTypeVR];
//            break;
//        case DemoType_AVPlayer_VR_Box:
//            self.player.displayMode = SGDisplayModeBox;
//            [self.player replaceVideoWithURL:vrVideo videoType:SGVideoTypeVR];
//            break;
//        case DemoType_FFmpeg_Normal:
//            self.player.decoder = [SGPlayerDecoder decoderByFFmpeg];
//            self.player.decoder.hardwareAccelerateEnableForFFmpeg = NO;
//            [self.player replaceVideoWithURL:normalVideo];
//            break;
//        case DemoType_FFmpeg_Normal_Hardware:
//            self.player.decoder = [SGPlayerDecoder decoderByFFmpeg];
//            [self.player replaceVideoWithURL:normalVideo];
//            break;
//        case DemoType_FFmpeg_VR:
//            self.player.decoder = [SGPlayerDecoder decoderByFFmpeg];
//            self.player.decoder.hardwareAccelerateEnableForFFmpeg = NO;
//            [self.player replaceVideoWithURL:vrVideo videoType:SGVideoTypeVR];
//            break;
//        case DemoType_FFmpeg_VR_Hardware:
//            self.player.decoder = [SGPlayerDecoder decoderByFFmpeg];
//            [self.player replaceVideoWithURL:vrVideo videoType:SGVideoTypeVR];
//            break;
//        case DemoType_FFmpeg_VR_Box:
//            self.player.displayMode = SGDisplayModeBox;
//            self.player.decoder = [SGPlayerDecoder decoderByFFmpeg];
//            self.player.decoder.hardwareAccelerateEnableForFFmpeg = NO;
//            [self.player replaceVideoWithURL:vrVideo videoType:SGVideoTypeVR];
//            break;
//        case DemoType_FFmpeg_VR_Box_Hardware:
//            self.player.displayMode = SGDisplayModeBox;
//            self.player.decoder = [SGPlayerDecoder decoderByFFmpeg];
//            [self.player replaceVideoWithURL:vrVideo videoType:SGVideoTypeVR];
//            break;
//    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.player.view.frame = self.view.bounds;
}

+ (NSString *)displayNameForDemoType:(DemoType)demoType
{
    static NSArray * displayNames = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        displayNames = @[@"i see fire,   AVPlayer",
                         @"google help,  AVPlayer,  VR",
                         @"google help,  AVPlayer,  VR,  Box",
                         @"i see fire,   FFmpeg",
                         @"i see fire,   FFmpeg,  Hardware Acceleration",
                         @"google help,  FFmpeg,  VR",
                         @"google help,  FFmpeg,  VR,  Hardware Acceleration",
                         @"google help,  FFmpeg,  VR,  Box",
                         @"google help,  FFmpeg,  VR,  Box,  Hardware Acceleration"];
    });
    if (demoType < displayNames.count) {
        return [displayNames objectAtIndex:demoType];
    }
    return nil;
}
- (IBAction)back:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)play:(id)sender
{
    [self.player play];
}

- (IBAction)pause:(id)sender
{
    [self.player pause];
}

- (IBAction)progressTouchDown:(id)sender
{
    self.progressSilderTouching = YES;
}

- (IBAction)progressTouchUp:(id)sender
{
    self.progressSilderTouching = NO;
    [self.player seekToTime:self.player.duration * self.progressSilder.value];
}

- (void)playbackStateAction:(NSNotification *)notification
{
    SGPlaybackStateModel * state = [notification.userInfo sg_playbackStateModel];
    
    NSString * text;
    switch (state.current) {
        case SGPlayerPlaybackStateIdle:
            text = @"Idle";
            break;
        case SGPlayerPlaybackStatePlaying:
            text = @"Playing";
            break;
        case SGPlayerPlaybackStateSeeking:
            text = @"Seeking";
            break;
        case SGPlayerPlaybackStatePaused:
            text = @"Paused";
            break;
        case SGPlayerPlaybackStateInterrupted:
            text = @"Interrupted";
            break;
        case SGPlayerPlaybackStateStopped:
            text = @"Stopped";
            break;
        case SGPlayerPlaybackStateFinished:
            text = @"Finished";
            break;
        case SGPlayerPlaybackStateFailed:
            text = @"Failed";
            break;
    }
    self.stateLabel.text = text;
}

- (void)loadStateAction:(NSNotification *)notification
{
    SGPlaybackStateModel * state = [notification.userInfo sg_playbackStateModel];
    NSLog(@"%s, %ld", __func__, state.current);
}

- (void)playbackTimeAction:(NSNotification *)notification
{
    SGTimeModel * progress = [notification.userInfo sg_playbackTimeModel];
    if (!self.progressSilderTouching) {
        self.progressSilder.value = progress.percent;
    }
    self.currentTimeLabel.text = [self timeStringFromSeconds:progress.current];
    self.totalTimeLabel.text = [self timeStringFromSeconds:progress.duration];
    NSLog(@"playback time : %f", progress.current);
}

- (void)loadedTimeAction:(NSNotification *)notification
{
    SGTimeModel * playable = [notification.userInfo sg_loadedTimeModel];
    NSLog(@"loaded time : %f", playable.current);
}

- (void)errorAction:(NSNotification *)notification
{
    NSError * error = [notification.userInfo sg_error];
    NSLog(@"player did error : %@", error);
}

- (NSString *)timeStringFromSeconds:(CGFloat)seconds
{
    return [NSString stringWithFormat:@"%ld:%.2ld", (long)seconds / 60, (long)seconds % 60];
}

- (void)dealloc
{
    [self sg_removeNotificationForPlayer:self.player];
}

@end
