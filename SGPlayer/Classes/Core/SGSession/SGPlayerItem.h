//
//  SGPlayerItem.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGAsset.h"
#import "SGTrack.h"

@interface SGPlayerItem : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithAsset:(SGAsset *)asset;

- (NSError *)error;

- (CMTime)duration;
- (NSDictionary *)metadata;
- (NSArray<SGTrack *> *)tracks;

@property (nonatomic, copy, readonly) NSArray<SGTrack *> * selectedAudioTracks;
@property (nonatomic, copy, readonly) NSArray<NSNumber *> * selectedAudioWeights;

- (BOOL)selectAudioTracks:(NSArray<SGTrack *> *)tracks weights:(NSArray<NSNumber *> *)weights;

@property (nonatomic, strong, readonly) SGTrack * selectedVideoTrack;

- (BOOL)selectVideoTrack:(SGTrack *)track;

@end
