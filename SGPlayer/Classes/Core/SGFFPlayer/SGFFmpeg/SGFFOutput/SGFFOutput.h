//
//  SGFFOutput.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#ifndef SGFFOutput_h
#define SGFFOutput_h


#import <Foundation/Foundation.h>
#import "SGFFFrame.h"
#import "SGFFOutputRender.h"
#import "SGFFTimeSynchronizer.h"


@protocol SGFFOutput;
@protocol SGFFOutputDelegate;


typedef NS_ENUM(NSUInteger, SGFFOutputType)
{
    SGFFOutputTypeUnkonwn,
    SGFFOutputTypeVideo,
    SGFFOutputTypeAudio,
    SGFFOutputTypeSubtitle,
};


@protocol SGFFOutput <NSObject>

- (SGFFOutputType)type;

@property (nonatomic, strong) SGFFTimeSynchronizer * timeSynchronizer;

@property (nonatomic, weak) id <SGFFOutputDelegate> delegate;

- (NSUInteger)count;
- (CMTime)duration;
- (long long)size;

- (void)flush;
- (void)close;

- (void)putFrame:(id <SGFFFrame>)frame;

@end


@protocol SGFFOutputDelegate <NSObject>

- (void)outputDidChangeCapacity:(id <SGFFOutput>)output;

@end


#endif /* SGFFOutput_h */
