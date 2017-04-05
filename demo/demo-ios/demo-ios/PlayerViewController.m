//
//  PlayerViewController.m
//  demo-ios
//
//  Created by Single on 2017/3/15.
//  Copyright © 2017年 single. All rights reserved.
//

#import "PlayerViewController.h"
#import <SGPlayer/SGPlayer.h>

@interface PlayerViewController ()

@property (nonatomic, strong) SGPlayer * player;

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
    
    self.player = [SGPlayer player];
    [self.player registerPlayerNotificationTarget:self
                                      stateAction:@selector(stateAction:)
                                   progressAction:@selector(progressAction:)
                                   playableAction:@selector(playableAction:)
                                      errorAction:@selector(errorAction:)];
    [self.player setViewTapAction:^(SGPlayer * _Nonnull player, SGPLFView * _Nonnull view) {
        NSLog(@"player display view did click!");
    }];
    [self.view insertSubview:self.player.view atIndex:0];
    
    static NSURL * normalVideo = nil;
    static NSURL * vrVideo = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        normalVideo = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"i-see-fire" ofType:@"mp4"]];
        vrVideo = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"google-help-vr" ofType:@"mp4"]];
    });
    switch (self.demoType)
    {
        case DemoType_AVPlayer_Normal:
            [self.player replaceVideoWithURL:normalVideo];
            break;
        case DemoType_AVPlayer_VR:
            [self.player replaceVideoWithURL:vrVideo videoType:SGVideoTypeVR];
            break;
        case DemoType_AVPlayer_VR_Box:
            self.player.displayMode = SGDisplayModeBox;
            [self.player replaceVideoWithURL:vrVideo videoType:SGVideoTypeVR];
            break;
        case DemoType_FFmpeg_Normal:
            self.player.decoder = [SGPlayerDecoder decoderByFFmpeg];
            self.player.decoder.hardwareAccelerateEnableForFFmpeg = NO;
            [self.player replaceVideoWithURL:normalVideo];
            break;
        case DemoType_FFmpeg_Normal_Hardware:
            self.player.decoder = [SGPlayerDecoder decoderByFFmpeg];
            [self.player replaceVideoWithURL:normalVideo];
            break;
        case DemoType_FFmpeg_VR:
            self.player.decoder = [SGPlayerDecoder decoderByFFmpeg];
            self.player.decoder.hardwareAccelerateEnableForFFmpeg = NO;
            [self.player replaceVideoWithURL:vrVideo videoType:SGVideoTypeVR];
            break;
        case DemoType_FFmpeg_VR_Hardware:
            self.player.decoder = [SGPlayerDecoder decoderByFFmpeg];
            [self.player replaceVideoWithURL:vrVideo videoType:SGVideoTypeVR];
            break;
        case DemoType_FFmpeg_VR_Box:
            self.player.displayMode = SGDisplayModeBox;
            self.player.decoder = [SGPlayerDecoder decoderByFFmpeg];
            self.player.decoder.hardwareAccelerateEnableForFFmpeg = NO;
            [self.player replaceVideoWithURL:vrVideo videoType:SGVideoTypeVR];
            break;
        case DemoType_FFmpeg_VR_Box_Hardware:
            self.player.displayMode = SGDisplayModeBox;
            self.player.decoder = [SGPlayerDecoder decoderByFFmpeg];
            [self.player replaceVideoWithURL:vrVideo videoType:SGVideoTypeVR];
            break;
    }
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

- (void)stateAction:(NSNotification *)notification
{
    SGState * state = [SGState stateFromUserInfo:notification.userInfo];
    
    NSString * text;
    switch (state.current) {
        case SGPlayerStateNone:
            text = @"None";
            break;
        case SGPlayerStateBuffering:
            text = @"Buffering...";
            break;
        case SGPlayerStateReadyToPlay:
            text = @"Prepare";
            self.totalTimeLabel.text = [self timeStringFromSeconds:self.player.duration];
            [self.player play];
            break;
        case SGPlayerStatePlaying:
            text = @"Playing";
            break;
        case SGPlayerStateSuspend:
            text = @"Suspend";
            break;
        case SGPlayerStateFinished:
            text = @"Finished";
            break;
        case SGPlayerStateFailed:
            text = @"Error";
            break;
    }
    self.stateLabel.text = text;
}

- (void)progressAction:(NSNotification *)notification
{
    SGProgress * progress = [SGProgress progressFromUserInfo:notification.userInfo];
    if (!self.progressSilderTouching) {
        self.progressSilder.value = progress.percent;
    }
    self.currentTimeLabel.text = [self timeStringFromSeconds:progress.current];
}

- (void)playableAction:(NSNotification *)notification
{
    SGPlayable * playable = [SGPlayable playableFromUserInfo:notification.userInfo];
    NSLog(@"playable time : %f", playable.current);
}

- (void)errorAction:(NSNotification *)notification
{
    SGError * error = [SGError errorFromUserInfo:notification.userInfo];
    NSLog(@"player did error : %@", error.error);
}

- (NSString *)timeStringFromSeconds:(CGFloat)seconds
{
    return [NSString stringWithFormat:@"%ld:%.2ld", (long)seconds / 60, (long)seconds % 60];
}

- (void)dealloc
{
    [self.player removePlayerNotificationTarget:self];
}

@end
