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

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    NSURL * contentURL1 = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"i-see-fire" ofType:@"mp4"]];
    NSURL * contentURL2 = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"google-help-vr" ofType:@"mp4"]];
    
//    NSMutableArray * assets = [NSMutableArray array];
//    for (int i = 0; i < 1; i++)
//    {
//        SGURLAsset2 * asset1 = [[SGURLAsset2 alloc] initWithURL:contentURL1];
////        asset1.scale = CMTimeMake(1, 3);
//        SGURLAsset2 * asset2 = [[SGURLAsset2 alloc] initWithURL:contentURL2];
//        [assets addObject:asset1];
//        [assets addObject:asset2];
//    }
//    SGConcatAsset * asset = [[SGConcatAsset alloc] initWithAssets:assets];
//    SGURLAsset * asset = [[SGURLAsset alloc] initWithURL:contentURL1];
    
    self.player = [[SGPlayer alloc] init];
    self.player.delegate = self;
    self.player.videoRenderer.view = self.view1;
    
//    self.player.hardwareDecodeH264 = NO;
    
    SGDiscardFilter * discardFilter = [[SGDiscardFilter alloc] init];
    discardFilter.minimumInterval = CMTimeMake(1, 30);
    
//    [self.player setCodecDiscardPacketFilter:^BOOL(CMSampleTimingInfo timingInfo, NSUInteger index, BOOL key) {
//        if (index == 0) {
//            [discardFilter flush];
//        }
//        return [discardFilter discardWithTimeStamp:timingInfo.decodeTimeStamp];
//    }];
    
//    [self.player setDisplayDiscardFilter:^BOOL(CMSampleTimingInfo timingInfo, NSUInteger index) {
//        if (index == 0) {
//            [discardFilter flush];
//        }
//        return [discardFilter discardWithTimeStamp:timingInfo.presentationTimeStamp];
//    }];
    
    [self.player.videoRenderer setRenderCallback:^(SGVideoFrame * frame) {
//        NSLog(@"Render : %f", CMTimeGetSeconds(frame.timeStamp));
    }];
    
//    [self.player replaceWithAsset:asset];
    [self.player replaceWithURL:contentURL1];
    [self.player waitUntilReady];
    NSLog(@"duration : %f", CMTimeGetSeconds(self.player.duration));
    [self.player play];
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
    NSLog(@"%s, playing  : %ld, %ld, %ld", __func__, state & SGPlaybackStatePlaying, state & SGPlaybackStateSeeking, state & SGPlaybackStateFinished);
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
//    NSLog(@"%s, %ld", __func__, state);
}

- (void)player:(SGPlayer *)player didChangeCurrentTime:(CMTime)time
{
    NSLog(@"%s, %f", __func__, CMTimeGetSeconds(time));
    self.currentTimeLabel.text = [self timeStringFromSeconds:CMTimeGetSeconds(time)];
    self.totalTimeLabel.text = [self timeStringFromSeconds:CMTimeGetSeconds(player.duration)];
}

- (void)player:(SGPlayer *)player didChangeLoadedTime:(CMTime)loadedTime loadedDuuration:(CMTime)loadedDuuration
{
    NSLog(@"%s, %f, %f", __func__, CMTimeGetSeconds(loadedTime), CMTimeGetSeconds(loadedDuuration));
}

- (NSString *)timeStringFromSeconds:(CGFloat)seconds
{
    return [NSString stringWithFormat:@"%ld:%.2ld", (long)seconds / 60, (long)seconds % 60];
}

@end
