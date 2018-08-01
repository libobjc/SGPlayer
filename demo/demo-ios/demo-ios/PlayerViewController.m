//
//  PlayerViewController.m
//  demo-ios
//
//  Created by Single on 2017/3/15.
//  Copyright © 2017年 single. All rights reserved.
//

#import "PlayerViewController.h"
#import <SGPlayer/SGPlayer.h>
//#import <SGAVPlayer/SGAVPlayer.h>

@interface PlayerViewController () <SGFFPlayerDelegate>

@property (nonatomic, strong) SGPlayer * player;
@property (nonatomic, strong) SGPlayer * player2;
@property (weak, nonatomic) IBOutlet UIView * view1;

@property (weak, nonatomic) IBOutlet UILabel * stateLabel;
@property (weak, nonatomic) IBOutlet UISlider * progressSilder;
@property (weak, nonatomic) IBOutlet UILabel * currentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel * totalTimeLabel;

@property (nonatomic, assign) BOOL progressSilderTouching;

@end

@implementation PlayerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    NSURL * contentURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"i-see-fire" ofType:@"mp4"]];
//    NSURL * contentURL2 = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"google-help-vr" ofType:@"mp4"]];
    
    self.player = [[SGPlayer alloc] init];
    self.player.delegate = self;
    self.player.view = self.view1;
    [self.player replaceWithURL:contentURL];
    
//    self.player2 = [[SGPlayer alloc] init];
//    self.player2.delegate = self;
//    [self.view insertSubview:self.player2.view atIndex:0];
//    [self.player2 replaceWithURL:contentURL2];
    
    [self.player play];
    [self.player2 play];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.player.view.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) / 2);
    self.player2.view.frame = CGRectMake(0, CGRectGetHeight(self.view.bounds) / 2, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) / 2);
}

- (IBAction)back:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)play:(id)sender
{
    [self.player play];
    [self.player2 play];
}

- (IBAction)pause:(id)sender
{
    [self.player pause];
    [self.player2 pause];
}

- (IBAction)progressTouchDown:(id)sender
{
    self.progressSilderTouching = YES;
}

- (IBAction)progressTouchUp:(id)sender
{
    self.progressSilderTouching = NO;
    CMTime time = CMTimeMultiplyByFloat64(self.player.duration, self.progressSilder.value);
    CMTime time2 = CMTimeMultiplyByFloat64(self.player2.duration, self.progressSilder.value);
    [self.player seekToTime:time];
    [self.player2 seekToTime:time2];
}

- (IBAction)progressValueChanged:(id)sender
{
    CMTime time = CMTimeMultiplyByFloat64(self.player.duration, self.progressSilder.value);
    CMTime time2 = CMTimeMultiplyByFloat64(self.player2.duration, self.progressSilder.value);
    [self.player seekToTime:time];
    [self.player2 seekToTime:time2];
}

- (void)player:(SGPlayer *)player didChangePlaybackState:(SGPlaybackState)playbackState
{
    NSLog(@"%s, %ld", __func__, playbackState);
    NSString * text;
    switch (playbackState) {
        case SGPlaybackStateNone:
            text = @"Idle";
            break;
        case SGPlaybackStatePlaying:
            text = @"Playing";
            break;
        case SGPlaybackStateSeeking:
            text = @"Seeking";
            break;
        case SGPlaybackStatePaused:
            text = @"Paused";
            break;
        case SGPlaybackStateStopped:
            text = @"Stopped";
            break;
        case SGPlaybackStateFinished:
            text = @"Finished";
            break;
        case SGPlaybackStateFailed:
            text = @"Failed";
            NSLog(@"%s, %@", __func__, player.error);
            break;
    }
    self.stateLabel.text = text;
}

- (void)player:(SGPlayer *)player didChangeLoadingState:(SGLoadingState)loadingState
{
    NSLog(@"%s, %ld", __func__, loadingState);
}

- (void)player:(SGPlayer *)player didChangePlaybackTime:(CMTime)playbackTime
{
    NSLog(@"%s, %f", __func__, CMTimeGetSeconds(playbackTime));
    if (!self.progressSilderTouching)
    {
        self.progressSilder.value = CMTimeGetSeconds(playbackTime) / CMTimeGetSeconds(player.duration);
    }
    self.currentTimeLabel.text = [self timeStringFromSeconds:CMTimeGetSeconds(playbackTime)];
    self.totalTimeLabel.text = [self timeStringFromSeconds:CMTimeGetSeconds(player.duration)];
}

- (void)player:(SGPlayer *)player didChangeLoadedTime:(CMTime)loadedTime
{
    NSLog(@"%s, %f", __func__, CMTimeGetSeconds(loadedTime));
}

- (NSString *)timeStringFromSeconds:(CGFloat)seconds
{
    return [NSString stringWithFormat:@"%ld:%.2ld", (long)seconds / 60, (long)seconds % 60];
}

@end
