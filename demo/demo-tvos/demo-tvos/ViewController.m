//
//  ViewController.m
//  demo-tvos
//
//  Created by Single on 2018/11/5.
//  Copyright © 2018 Single. All rights reserved.
//

#import "ViewController.h"
#import <SGPlayer/SGPlayer.h>

@interface ViewController ()

@property (nonatomic, assign) BOOL seeking;
@property (nonatomic, strong) SGPlayer *player;

@end

@implementation ViewController

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
    
    NSURL *URL = [[NSBundle mainBundle] URLForResource:@"i-see-fire" withExtension:@"mp4"];
    SGAsset *asset = [[SGURLAsset alloc] initWithURL:URL];
    
    self.player.videoRenderer.view = self.view;
    [self.player replaceWithAsset:asset];
    [self.player play];
}

#pragma mark - SGPlayer Notifications

- (void)infoChanged:(NSNotification *)notification
{
    SGTimeInfo time = [SGPlayer timeInfoFromUserInfo:notification.userInfo];
    SGStateInfo state = [SGPlayer stateInfoFromUserInfo:notification.userInfo];
    SGInfoAction action = [SGPlayer infoActionFromUserInfo:notification.userInfo];
    if (action & SGInfoActionTime) {
        NSLog(@"playback: %f, duration: %f, cached: %f",
              CMTimeGetSeconds(time.playback),
              CMTimeGetSeconds(time.duration),
              CMTimeGetSeconds(time.cached));
    }
    if (action & SGInfoActionState) {
        NSLog(@"player: %d, loading: %d, playback: %d, playing: %d, seeking: %d, finished: %d",
              (int)state.player, (int)state.loading, (int)state.playback,
              (int)(state.playback & SGPlaybackStatePlaying),
              (int)(state.playback & SGPlaybackStateSeeking),
              (int)(state.playback & SGPlaybackStateFinished));
    }
}

@end
