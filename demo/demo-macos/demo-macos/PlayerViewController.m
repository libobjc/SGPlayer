//
//  PlayerViewController.m
//  demo-macos
//
//  Created by Single on 2017/3/15.
//  Copyright © 2017年 single. All rights reserved.
//

#import "PlayerViewController.h"
#import <SGPlayer/SGPlayer.h>

@interface PlayerViewController ()

@property (nonatomic, strong) SGPlayer * player;
@property (weak) IBOutlet NSTextField *totalTimeLabel;
@property (weak) IBOutlet NSTextField *currentTimeLabel;
@property (weak) IBOutlet NSSlider *progressSilder;
@property (weak) IBOutlet NSButton *playButton;
@property (weak) IBOutlet NSButton *pauseButton;
@property (weak) IBOutlet NSTextField *stateLabel;
@property (weak) IBOutlet NSView *controlView;

@end

@implementation PlayerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = [NSColor blackColor].CGColor;
    self.controlView.wantsLayer = YES;
    self.controlView.layer.backgroundColor = [NSColor colorWithWhite:0 alpha:0.5].CGColor;
    self.progressSilder.trackFillColor = [NSColor yellowColor];
}

- (void)setup
{
    self.player = [SGPlayer player];
    [self.player registerPlayerNotificationTarget:self
                                      stateAction:@selector(stateAction:)
                                   progressAction:@selector(progressAction:)
                                   playableAction:@selector(playableAction:)
                                      errorAction:@selector(errorAction:)];
    [self.view addSubview:self.player.view positioned:NSWindowBelow relativeTo:nil];
    
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
        case DemoType_FFmpeg_Normal:
            self.player.decoder = [SGPlayerDecoder decoderByFFmpeg];
            self.player.decoder.hardwareAccelerateEnableForFFmpeg = NO;
            [self.player replaceVideoWithURL:normalVideo];
            break;
        case DemoType_FFmpeg_VR:
            self.player.decoder = [SGPlayerDecoder decoderByFFmpeg];
            self.player.decoder.hardwareAccelerateEnableForFFmpeg = NO;
            [self.player replaceVideoWithURL:vrVideo videoType:SGVideoTypeVR];
            break;
    }
}

- (void)viewDidLayout
{
    self.player.view.frame = self.view.bounds;
}

- (IBAction)play:(id)sender
{
    [self.player play];
}

- (IBAction)pause:(id)sender
{
    [self.player pause];
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
            self.totalTimeLabel.stringValue = [self timeStringFromSeconds:self.player.duration];
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
    self.stateLabel.stringValue = text;
}

- (void)progressAction:(NSNotification *)notification
{
    SGProgress * progress = [SGProgress progressFromUserInfo:notification.userInfo];
    self.progressSilder.doubleValue = progress.percent;
    self.currentTimeLabel.stringValue = [self timeStringFromSeconds:progress.current];
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
