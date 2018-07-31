//
//  PlayerViewController.m
//  demo-macos
//
//  Created by Single on 2017/3/15.
//  Copyright © 2017年 single. All rights reserved.
//

#import "PlayerViewController.h"
#import <SGAVPlayer/SGAVPlayer.h>

@interface PlayerViewController ()

@property (nonatomic, strong) SGAVPlayer * player;
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
    self.player = [[SGAVPlayer alloc] init];
    [self sg_registerNotificationForPlayer:self.player
                       playbackStateAction:@selector(playbackStateAction:)
                           loadStateAction:@selector(loadStateAction:)
                         currentTimeAction:@selector(currentTimeAction:)
                              loadedAction:@selector(loadedTimeAction:)
                               errorAction:@selector(errorAction:)];
    [self.view addSubview:self.player.view positioned:NSWindowBelow relativeTo:nil];
    
    NSURL * contentURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"i-see-fire" ofType:@"mp4"]];
    //    NSURL * contentURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"google-help-vr" ofType:@"mp4"]];
    [self.player replaceWithContentURL:contentURL];
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

- (void)playbackStateAction:(NSNotification *)notification
{
    SGPlaybackStateModel * playbackStateModel = [notification.userInfo sg_playbackStateModel];
    
    NSString * text;
    switch (playbackStateModel.current) {
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
    self.stateLabel.stringValue = text;
    
    NSLog(@"%s, %ld", __func__, playbackStateModel.current);
}

- (void)loadStateAction:(NSNotification *)notification
{
    SGPlaybackStateModel * loadStateModel = [notification.userInfo sg_playbackStateModel];
    
    NSLog(@"%s, %ld", __func__, loadStateModel.current);
    
    if (loadStateModel.current == SGPlayerLoadingStatePlayable && self.player.playbackState == SGPlayerLoadingStateNone) {
        [self.player play];
    }
}

- (void)currentTimeAction:(NSNotification *)notification
{
    SGTimeModel * currentTimeModel = [notification.userInfo sg_currentTimeModel];
    
    NSLog(@"%s, %f", __func__, currentTimeModel.current);
    
    self.progressSilder.doubleValue = currentTimeModel.percent;
    self.currentTimeLabel.stringValue = [self timeStringFromSeconds:currentTimeModel.current];
    self.totalTimeLabel.stringValue = [self timeStringFromSeconds:currentTimeModel.duration];
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
