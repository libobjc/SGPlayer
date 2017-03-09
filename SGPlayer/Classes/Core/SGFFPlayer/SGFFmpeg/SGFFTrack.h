//
//  SGFFTrack.h
//  SGPlayer
//
//  Created by Single on 2017/3/6.
//  Copyright © 2017年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFMetadata.h"

typedef NS_ENUM(NSUInteger, SGFFTrackType) {
    SGFFTrackTypeVideo,
    SGFFTrackTypeAudio,
    SGFFTrackTypeSubtitle,
};

@interface SGFFTrack : NSObject

@property (nonatomic, assign) int index;
@property (nonatomic, assign) SGFFTrackType type;
@property (nonatomic, strong) SGFFMetadata * metadata;

@end
