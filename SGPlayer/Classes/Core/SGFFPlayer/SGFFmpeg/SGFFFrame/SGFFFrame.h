//
//  SGFFFrame.h
//  SGPlayer
//
//  Created by Single on 2018/1/18.
//  Copyright © 2018年 single. All rights reserved.
//

#ifndef SGFFFrame_h
#define SGFFFrame_h


#import <Foundation/Foundation.h>
#import "SGFFTime.h"


typedef NS_ENUM(NSUInteger, SGFFFrameType)
{
    SGFFFrameTypeUnkonwn,
    SGFFFrameTypeVideo,
    SGFFFrameTypeAudio,
    SGFFFrameTypeSubtitle,
};


@protocol SGFFFrame <NSObject>

- (SGFFFrameType)type;

- (SGFFTimebase)timebase;
- (long long)position;
- (long long)duration;
- (long long)size;

@end


#endif /* SGFFFrame_h */
