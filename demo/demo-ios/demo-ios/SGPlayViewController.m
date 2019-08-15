//
//  SGPlayViewController.m
//  demo-ios
//
//  Created by Single on 2017/3/15.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPlayViewController.h"

@interface SGPlayViewController ()

@property (nonatomic, assign) BOOL seeking;
@property (nonatomic, strong) SGPlayer *player;

@property (weak, nonatomic) IBOutlet UILabel *stateLabel;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UISlider *progressSilder;

@end

@implementation SGPlayViewController

- (instancetype)init
{
    if (self = [super init]) {
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
        if (action & SGInfoActionTimePlayback && !(state.playback & SGPlaybackStateSeeking) && !self.seeking && !self.progressSilder.isTracking) {
            self.progressSilder.value = CMTimeGetSeconds(time.playback) / CMTimeGetSeconds(time.duration);
            self.currentTimeLabel.text = [self timeStringFromSeconds:CMTimeGetSeconds(time.playback)];
        }
        if (action & SGInfoActionTimeDuration) {
            self.durationLabel.text = [self timeStringFromSeconds:CMTimeGetSeconds(time.duration)];
        }
    }
    if (action & SGInfoActionState) {
        if (state.playback & SGPlaybackStateFinished) {
            self.stateLabel.text = @"Finished";
        } else if (state.playback & SGPlaybackStatePlaying) {
            self.stateLabel.text = @"Playing";
        } else {
            self.stateLabel.text = @"Paused";
        }
    }
}

#pragma mark - Actions

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

- (IBAction)progressTouchUp:(id)sender
{
    CMTime time = CMTimeMultiplyByFloat64(self.player.currentItem.duration, self.progressSilder.value);
    if (!CMTIME_IS_NUMERIC(time)) {
        time = kCMTimeZero;
    }
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
