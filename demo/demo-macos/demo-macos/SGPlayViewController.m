//
//  SGPlayViewController.m
//  demo-macos
//
//  Created by Single on 2017/3/15.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPlayViewController.h"

@interface SGPlayViewController ()

@property (nonatomic, assign) BOOL seeking;
@property (nonatomic, strong) SGPlayer *player;

@property (weak) IBOutlet NSView *controlView;
@property (weak) IBOutlet NSButton *playButton;
@property (weak) IBOutlet NSButton *pauseButton;
@property (weak) IBOutlet NSSlider *progressSilder;
@property (weak) IBOutlet NSTextField *stateLabel;
@property (weak) IBOutlet NSTextField *durationLabel;
@property (weak) IBOutlet NSTextField *currentTimeLabel;

@end

@implementation SGPlayViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        self.player = [[SGPlayer alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(infoChanged:) name:SGPlayerDidChangeInfosNotification object:self.player];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = [NSColor blackColor].CGColor;
    self.controlView.wantsLayer = YES;
    self.controlView.layer.backgroundColor = [NSColor colorWithWhite:0 alpha:0.5].CGColor;
    self.progressSilder.trackFillColor = [NSColor yellowColor];
    
}

- (void)run
{
    self.player.videoRenderer.view = self.view;
    self.player.videoRenderer.displayMode = self.videoItem.displayMode;
    [self.player replaceWithAsset:self.videoItem.asset];
    [self.player play];
}

#pragma mark - SGPlayer Notifications

- (void)infoChanged:(NSNotification *)notification
{
    SGTimeInfo time = [SGPlayer timeInfoFromUserInfo:notification.userInfo];
    SGStateInfo state = [SGPlayer stateInfoFromUserInfo:notification.userInfo];
    SGInfoAction action = [SGPlayer infoActionFromUserInfo:notification.userInfo];
    if (action & SGInfoActionTime) {
        if (action & SGInfoActionTimePlayback && !(state.playback & SGPlaybackStateSeeking) && !self.seeking && !self.progressSilder.isHighlighted) {
            self.progressSilder.doubleValue = CMTimeGetSeconds(time.playback) / CMTimeGetSeconds(time.duration);
            self.currentTimeLabel.stringValue = [self timeStringFromSeconds:CMTimeGetSeconds(time.playback)];
        }
        if (action & SGInfoActionTimeDuration) {
            self.durationLabel.stringValue = [self timeStringFromSeconds:CMTimeGetSeconds(time.duration)];
        }
    }
    if (action & SGInfoActionState) {
        if (state.playback & SGPlaybackStateFinished) {
            self.stateLabel.stringValue = @"Finished";
        } else if (state.playback & SGPlaybackStatePlaying) {
            self.stateLabel.stringValue = @"Playing";
        } else {
            self.stateLabel.stringValue = @"Paused";
        }
    }
}

#pragma mark - Actions

- (IBAction)play:(id)sender
{
    [self.player play];
}

- (IBAction)pause:(id)sender
{
    [self.player pause];
}

- (IBAction)progressValueChanged:(id)sender
{
    CMTime time = CMTimeMultiplyByFloat64(self.player.currentItem.duration, self.progressSilder.doubleValue);
    self.seeking = YES;
    [self.player seekToTime:time result:^(CMTime time, NSError *error) {
        self.seeking = NO;
    }];
}

#pragma mark - Tools

- (NSString *)timeStringFromSeconds:(CGFloat)seconds
{
    return [NSString stringWithFormat:@"%ld:%.2ld", (long)seconds / 60, (long)seconds % 60];
}

@end
