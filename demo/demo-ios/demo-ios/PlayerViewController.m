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

@interface PlayerViewController ()

@property (nonatomic, strong) SGFFPlayer * player;

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
    
    self.player = [[SGFFPlayer alloc] init];
    [self sg_registerNotificationForPlayer:self.player
                       playbackStateAction:@selector(playbackStateAction:)
                           loadStateAction:@selector(loadStateAction:)
                        currentTimeAction:@selector(currentTimeAction:)
                              loadedAction:@selector(loadedTimeAction:)
                               errorAction:@selector(errorAction:)];
    [self.view insertSubview:self.player.view atIndex:0];
    
    NSURL * contentURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"i-see-fire" ofType:@"mp4"]];
//    NSURL * contentURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"google-help-vr" ofType:@"mp4"]];
    [self.player replaceWithContentURL:contentURL];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.player.view.frame = self.view.bounds;
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
    [self.player seekToTime:60 * self.progressSilder.value];
}

- (void)playbackStateAction:(NSNotification *)notification
{
    SGPlaybackStateModel * playbackStateModel = [notification.userInfo sg_playbackStateModel];
    
    NSString * text;
    switch (playbackStateModel.current) {
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
    
    NSLog(@"%s, %ld", __func__, playbackStateModel.current);
}

- (void)loadStateAction:(NSNotification *)notification
{
    SGPlaybackStateModel * loadStateModel = [notification.userInfo sg_playbackStateModel];
    
    NSLog(@"%s, %ld", __func__, loadStateModel.current);
    
    if (loadStateModel.current == SGPlayerLoadStatePlayable && self.player.playbackState == SGPlayerLoadStateIdle) {
        [self.player play];
    }
}

- (void)currentTimeAction:(NSNotification *)notification
{
    SGTimeModel * currentTimeModel = [notification.userInfo sg_currentTimeModel];
    
    NSLog(@"%s, %f", __func__, currentTimeModel.current);
    
    if (!self.progressSilderTouching) {
        self.progressSilder.value = currentTimeModel.percent;
    }
    self.currentTimeLabel.text = [self timeStringFromSeconds:currentTimeModel.current];
    self.totalTimeLabel.text = [self timeStringFromSeconds:currentTimeModel.duration];
}

- (void)loadedTimeAction:(NSNotification *)notification
{
    SGTimeModel * loadedTimeModel = [notification.userInfo sg_loadedTimeModel];
    NSLog(@"%s, %f", __func__, loadedTimeModel.current);
}

- (void)errorAction:(NSNotification *)notification
{
    NSError * error = [notification.userInfo sg_error];
    NSLog(@"%s, %@", __func__, error);
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
