//
//  ViewController.m
//  demo-tvos
//
//  Created by Single on 2018/11/5.
//  Copyright © 2018 Single. All rights reserved.
//

#import "ViewController.h"
#import <SGPlayer/SGPlayer.h>

@interface ViewController () <SGPlayerDelegate>

@property (nonatomic, strong) SGPlayer * player;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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

#pragma mark - SGPlayerDelegate

- (void)player:(SGPlayer *)player didChangeStatus:(SGPlayerStatus)status
{
    //    NSLog(@"%s, %ld", __func__, status);
}

- (void)player:(SGPlayer *)player didChangePlaybackState:(SGPlaybackState)state
{
//    NSLog(@"%s, playing  : %d, %d, %d", __func__, state & SGPlaybackStatePlaying, state & SGPlaybackStateSeeking, state & SGPlaybackStateFinished);
}

- (void)player:(SGPlayer *)player didChangeLoadingState:(SGLoadingState)state
{
//    NSLog(@"%s, %d", __func__, state);
}

- (void)player:(SGPlayer *)player didChangeCurrentTime:(CMTime)currentTime duration:(CMTime)duration
{
//        NSLog(@"%s, %f", __func__, CMTimeGetSeconds(currentTime));
}

- (void)player:(SGPlayer *)player didChangeLoadedTime:(CMTime)loadedTime loadedDuuration:(CMTime)loadedDuuration
{
    //    NSLog(@"%s, %f, %f", __func__, CMTimeGetSeconds(loadedTime), CMTimeGetSeconds(loadedDuuration));
}

@end
