//
//  PlayerViewController.m
//  demo-macos
//
//  Created by Single on 2017/3/15.
//  Copyright © 2017年 single. All rights reserved.
//

#import "PlayerViewController.h"
#import <SGPlayer/SGPlayer.h>

@interface PlayerViewController () <SGPlayerDelegate>

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
    NSURL * URL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"i-see-fire" ofType:@"mp4"]];
    
    self.player = [[SGPlayer alloc] init];
    self.player.delegate = self;
    self.player.videoRenderer.view = self.view;
//    self.player.videoRenderer.displayMode = SGDisplayModeVR;
//    [self.player.videoRenderer setFrameOutput:^(SGVideoFrame * frame) {
//        NSLog(@"frame output : %f", CMTimeGetSeconds(frame.timeStamp));
//    }];
    [self.player replaceWithURL:URL];
    [self.player waitUntilReady];
    [self.player play];
}

- (IBAction)play:(id)sender
{
    [self.player play];
}

- (IBAction)pause:(id)sender
{
    [self.player pause];
}

- (void)player:(SGPlayer *)player didChangeStatus:(SGPlayerStatus)status
{
//    NSLog(@"%s, %ld", __func__, status);
}

- (void)player:(SGPlayer *)player didChangePlaybackState:(SGPlaybackState)state
{
//    NSLog(@"%s, playing  : %d, %d, %d", __func__, state & SGPlaybackStatePlaying, state & SGPlaybackStateSeeking, state & SGPlaybackStateFinished);
    if (state & SGPlaybackStateFinished) {
        self.stateLabel.stringValue = @"Finished";
    } else if (state & SGPlaybackStatePlaying) {
        self.stateLabel.stringValue = @"Playing";
    } else {
        self.stateLabel.stringValue = @"Paused";
    }
}

- (void)player:(SGPlayer *)player didChangeCurrentTime:(CMTime)currentTime duration:(CMTime)duration
{
//    NSLog(@"%s, %f", __func__, CMTimeGetSeconds(currentTime));
    self.progressSilder.doubleValue = CMTimeGetSeconds(currentTime) / CMTimeGetSeconds(duration);
    self.currentTimeLabel.stringValue = [self timeStringFromSeconds:CMTimeGetSeconds(currentTime)];
    self.totalTimeLabel.stringValue = [self timeStringFromSeconds:CMTimeGetSeconds(duration)];
}

- (void)player:(SGPlayer *)player didChangeLoadedTime:(CMTime)loadedTime loadedDuuration:(CMTime)loadedDuuration
{
//    NSLog(@"%s, %f, %f", __func__, CMTimeGetSeconds(loadedTime), CMTimeGetSeconds(loadedDuuration));
}

- (NSString *)timeStringFromSeconds:(CGFloat)seconds
{
    return [NSString stringWithFormat:@"%ld:%.2ld", (long)seconds / 60, (long)seconds % 60];
}

@end
