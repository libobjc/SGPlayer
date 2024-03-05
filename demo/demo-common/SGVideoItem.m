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
        item.asset = [SGAsset assetWithURL:i_see_fire];
        item.displayMode = SGDisplayModePlane;
        [items addObject:item];
    }
    {
        SGMutableAsset *asset = [[SGMutableAsset alloc] init];
        SGMutableTrack *track = [asset addTrack:SGMediaTypeVideo];
        SGSegment *segment = [SGSegment segmentWithURL:i_see_fire index:0];
        [track appendSegment:segment];
        
        SGVideoItem *item = [[SGVideoItem alloc] init];
        item.name = @"I See Fire, Video Track";
        item.asset = asset;
        item.displayMode = SGDisplayModePlane;
        [items addObject:item];
    }
    {
        SGMutableAsset *asset = [[SGMutableAsset alloc] init];
        SGMutableTrack *track = [asset addTrack:SGMediaTypeAudio];
        SGSegment *segment = [SGSegment segmentWithURL:i_see_fire index:1];
        [track appendSegment:segment];
        
        SGVideoItem *item = [[SGVideoItem alloc] init];
        item.name = @"I See Fire, Audio Track";
        item.asset = asset;
        item.displayMode = SGDisplayModePlane;
        [items addObject:item];
    }
    {
        CMTime scale = kCMTimeInvalid;
        CMTimeRange timeRange = CMTimeRangeMake(CMTimeMake(30, 1), CMTimeMake(10, 1));
        
        SGMutableAsset *asset = [[SGMutableAsset alloc] init];
        {
            SGMutableTrack *track = [asset addTrack:SGMediaTypeAudio];
            SGSegment *segment = [SGSegment segmentWithURL:i_see_fire index:1 timeRange:timeRange scale:scale];
            [track appendSegment:segment];
        }
        {
            SGMutableTrack *track = [asset addTrack:SGMediaTypeVideo];
            SGSegment *segment = [SGSegment segmentWithURL:i_see_fire index:0 timeRange:timeRange scale:scale];
            [track appendSegment:segment];
        }
        
        SGVideoItem *item = [[SGVideoItem alloc] init];
        item.name = @"I See Fire, Range: 30s-40s";
        item.asset = asset;
        item.displayMode = SGDisplayModePlane;
        [items addObject:item];
    }
    {
        CMTime scale = CMTimeMake(1, 2);
        CMTimeRange timeRange = CMTimeRangeMake(CMTimeMake(30, 1), CMTimeMake(20, 1));
        
        SGMutableAsset *asset = [[SGMutableAsset alloc] init];
        {
            SGMutableTrack *track = [asset addTrack:SGMediaTypeAudio];
            SGSegment *segment = [SGSegment segmentWithURL:i_see_fire index:1 timeRange:timeRange scale:scale];
            [track appendSegment:segment];
        }
        {
            SGMutableTrack *track = [asset addTrack:SGMediaTypeVideo];
            SGSegment *segment = [SGSegment segmentWithURL:i_see_fire index:0 timeRange:timeRange scale:scale];
            [track appendSegment:segment];
        }
        
        SGVideoItem *item = [[SGVideoItem alloc] init];
        item.name = @"I See Fire, Range: 30s-50s, Scale: 0.5";
        item.asset = asset;
        item.displayMode = SGDisplayModePlane;
        [items addObject:item];
    }
    {
        SGMutableAsset *asset = [[SGMutableAsset alloc] init];
        {
            SGMutableTrack *track = [asset addTrack:SGMediaTypeAudio];
            SGSegment *segment1 = [SGURLSegment segmentWithURL:i_see_fire index:1];
            SGSegment *segment2 = [SGURLSegment segmentWithURL:google_help_vr index:1];
            [track appendSegment:segment1];
            [track appendSegment:segment2];
        }
        {
            SGMutableTrack *track = [asset addTrack:SGMediaTypeVideo];
            SGSegment *segment1 = [SGURLSegment segmentWithURL:i_see_fire index:0];
            SGSegment *segment2 = [SGURLSegment segmentWithURL:google_help_vr index:0];
            [track appendSegment:segment1];
            [track appendSegment:segment2];
        }
        
        SGVideoItem *item = [[SGVideoItem alloc] init];
        item.name = @"I See Fire + Google Help";
        item.asset = asset;
        item.displayMode = SGDisplayModePlane;
        [items addObject:item];
    }
    {
        SGVideoItem *item = [[SGVideoItem alloc] init];
        item.name = @"Google Help VR";
        item.asset = [SGAsset assetWithURL:google_help_vr];
        item.displayMode = SGDisplayModeVR;
        [items addObject:item];
    }
    return items;
}

@end
