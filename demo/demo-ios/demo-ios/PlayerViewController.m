//
//  PlayerViewController.m
//  demo-ios
//
//  Created by Single on 2017/3/15.
//  Copyright © 2017年 single. All rights reserved.
//

#import "PlayerViewController.h"
#import <SGPlayer/SGPlayer.h>

@interface PlayerViewController () <SGPlayerDelegate>

@property (nonatomic, strong) SGPlayer * player;
@property (nonatomic, strong) SGPlayer * player2;
@property (weak, nonatomic) IBOutlet UIView * view1;
@property (weak, nonatomic) IBOutlet UIView * view2;

@property (weak, nonatomic) IBOutlet UILabel * stateLabel;
@property (weak, nonatomic) IBOutlet UISlider * progressSilder;
@property (weak, nonatomic) IBOutlet UILabel * currentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel * totalTimeLabel;

@property (nonatomic, assign) BOOL progressSilderTouching;

@end

@implementation PlayerViewController

- (void)dealloc
{
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSURL * URL1 = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"i-see-fire" ofType:@"mp4"]];
//    NSURL * URL2 = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"google-help-vr" ofType:@"mp4"]];
    
    SGMutableAsset * asset = [[SGMutableAsset alloc] init];
    int32_t trackID = [asset addTrack:SGMediaTypeVideo];
    [asset insertSegment:[[SGURLSegment alloc] initWithURL:URL1 index:0 timeRange:CMTimeRangeMake(CMTimeMake(0, 1), CMTimeMake(10, 1)) scale:kCMTimeInvalid] trackID:trackID];
    [asset insertSegment:[[SGURLSegment alloc] initWithURL:URL1 index:0 timeRange:CMTimeRangeMake(CMTimeMake(0, 1), CMTimeMake(10, 1)) scale:kCMTimeInvalid] trackID:trackID];
//    return;
    
    [SGConfiguration defaultConfiguration].hardwareDecodeH264 = YES;
    self.player = [[SGPlayer alloc] init];
    self.player.delegate = self;
    self.player.videoRenderer.view = self.view1;
//    self.player.videoRenderer.displayMode = SGDisplayModeVR;
//    [self.player.videoRenderer setFrameOutput:^(SGVideoFrame * frame) {
//        NSLog(@"1 frame output : %f", CMTimeGetSeconds(frame.timeStamp));
//    }];
//    [self.player replaceWithURL:URL1];
    [self.player replaceWithAsset:asset];
    [self.player waitUntilReady];
    [self.player play];
    
//    self.player2 = [[SGPlayer alloc] init];
//    self.player2.delegate = self;
//    self.player2.videoRenderer.view = self.view2;
//    self.player2.videoRenderer.displayMode = SGDisplayModeVR;
//    [self.player2.videoRenderer setFrameOutput:^(SGVideoFrame * frame) {
//        NSLog(@"2 frame output : %f", CMTimeGetSeconds(frame.timeStamp));
//    }];
//    [self.player2 replaceWithURL:URL2];
//    [self.player2 waitUntilReady];
//    [self.player2 play];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.player.videoRenderer.view.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) / 2);
    self.player2.videoRenderer.view.frame = CGRectMake(0, CGRectGetHeight(self.view.bounds) / 2, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) / 2);
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
    CMTime time = CMTimeMultiplyByFloat64(self.player.currentItem.duration, self.progressSilder.value);
    CMTime time2 = CMTimeMultiplyByFloat64(self.player2.currentItem.duration, self.progressSilder.value);
    [self.player seekToTime:time result:nil];
    [self.player2 seekToTime:time2 result:nil];
}

- (IBAction)progressValueChanged:(id)sender
{
//    CMTime time = CMTimeMultiplyByFloat64(self.player.duration, self.progressSilder.value);
//    CMTime time2 = CMTimeMultiplyByFloat64(self.player2.duration, self.progressSilder.value);
//    [self.player seekToTime:time result:nil];
//    [self.player2 seekToTime:time2 result:nil];
}

#pragma mark - SGPlayerDelegate

- (void)player:(SGPlayer *)player didChangeStatus:(SGPlayerStatus)status
{
//    NSLog(@"%s, %ld", __func__, status);
}

- (void)player:(SGPlayer *)player didChangePlaybackState:(SGPlaybackState)state
{
    NSLog(@"%s, playing  : %d, %d, %d", __func__, state & SGPlaybackStatePlaying, state & SGPlaybackStateSeeking, state & SGPlaybackStateFinished);
    if (state & SGPlaybackStateFinished) {
        self.stateLabel.text = @"Finished";
    } else if (state & SGPlaybackStatePlaying) {
        self.stateLabel.text = @"Playing";
    } else {
        self.stateLabel.text = @"Paused";
    }
}

- (void)player:(SGPlayer *)player didChangeLoadingState:(SGLoadingState)state
{
    NSLog(@"%s, %d", __func__, state);
}

- (void)player:(SGPlayer *)player didChangeCurrentTime:(CMTime)currentTime duration:(CMTime)duration
{
//    NSLog(@"%s, %f", __func__, CMTimeGetSeconds(currentTime));
    if (!self.progressSilderTouching) {
        self.progressSilder.value = CMTimeGetSeconds(currentTime) / CMTimeGetSeconds(duration);
    }
    self.currentTimeLabel.text = [self timeStringFromSeconds:CMTimeGetSeconds(currentTime)];
    self.totalTimeLabel.text = [self timeStringFromSeconds:CMTimeGetSeconds(duration)];
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
