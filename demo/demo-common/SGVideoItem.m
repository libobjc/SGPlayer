//
//  SGVideoItem.m
//  demo-common
//
//  Created by Single on 2017/3/15.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGVideoItem.h"

@implementation SGVideoItem

+ (NSArray<SGVideoItem *> *)videoItems
{
    NSURL *i_see_fire = [[NSBundle mainBundle] URLForResource:@"i-see-fire" withExtension:@"mp4"];
    NSURL *google_help_vr = [[NSBundle mainBundle] URLForResource:@"google-help-vr" withExtension:@"mp4"];
    
    NSMutableArray *items = [NSMutableArray array];
    {
        SGVideoItem *item = [[SGVideoItem alloc] init];
        item.name = @"I See Fire";
        item.asset = [[SGURLAsset alloc] initWithURL:i_see_fire];
        item.displayMode = SGDisplayModePlane;
        [items addObject:item];
    }
    {
        SGVideoItem *item = [[SGVideoItem alloc] init];
        item.name = @"Google Help VR";
        item.asset = [[SGURLAsset alloc] initWithURL:google_help_vr];
        item.displayMode = SGDisplayModeVR;
        [items addObject:item];
    }
    //rtsp://184.72.239.149/vod/mp4://BigBuckBunny_175k.mov
    //http://ivi.bupt.edu.cn/hls/cctv5phd.m3u8
    //rtmp://live.hkstv.hk.lxdns.com/live/hks1
    return items;
}

@end
