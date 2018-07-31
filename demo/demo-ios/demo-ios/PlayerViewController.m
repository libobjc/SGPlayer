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

@property (nonatomic, strong) SGFFPlayer * player;
@property (nonatomic, strong) SGFFPlayer * player2;

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
    NSURL * contentURL2 = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"google-help-vr" ofType:@"mp4"]];
    
    self.player = [[SGFFPlayer alloc] init];
    self.player.delegate = self;
    [self.view insertSubview:self.player.view atIndex:0];
    [self.player replaceWithContentURL:contentURL];
    
    
    
    self.player2 = [[SGFFPlayer alloc] init];
    self.player2.delegate = self;
    [self.view insertSubview:self.player2.view atIndex:0];
    [self.player2 replaceWithContentURL:contentURL2];
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

- (void)playerDidChangePlaybackState:(SGFFPlayer *)player
{
    NSString * text;
    switch (player.playbackState) {
        case SGPlayerPlaybackStateNone:
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
        case SGPlayerPlaybackStateStopped:
            text = @"Stopped";
            break;
        case SGPlayerPlaybackStateFinished:
            text = @"Finished";
            break;
        case SGPlayerPlaybackStateFailed:
            text = @"Failed";
            NSLog(@"%s, %@", __func__, player.error);
            break;
    }
    self.stateLabel.text = text;
    
    NSLog(@"%s, %ld", __func__, player.playbackState);
}

- (void)playerDidChangeLoadingState:(SGFFPlayer *)player
{
    NSLog(@"%s, %ld", __func__, player.loadingState);
    
//    if (player.loadingState == SGPlayerLoadingStatePlayable && player.playbackState == SGPlayerLoadingStateNone)
//    {
//        [player play];
//    }
}

- (void)playerDidChangePlaybackTime:(SGFFPlayer *)player
{
    NSLog(@"%s, %f", __func__, CMTimeGetSeconds(player.playbackTime));
    
    if (!self.progressSilderTouching)
    {
        self.progressSilder.value = CMTimeGetSeconds(player.playbackTime) / CMTimeGetSeconds(player.duration);
    }
    self.currentTimeLabel.text = [self timeStringFromSeconds:CMTimeGetSeconds(player.playbackTime)];
    self.totalTimeLabel.text = [self timeStringFromSeconds:CMTimeGetSeconds(player.duration)];
}

- (void)playerDidChangeLoadedTime:(SGFFPlayer *)player
{
    NSLog(@"%s, %f", __func__, CMTimeGetSeconds(player.loadedTime));
}

- (NSString *)timeStringFromSeconds:(CGFloat)seconds
{
    return [NSString stringWithFormat:@"%ld:%.2ld", (long)seconds / 60, (long)seconds % 60];
}

@end
