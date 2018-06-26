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
#import "SGDefines.h"
#import "SGFFFrame.h"
#import "SGFFTimeSynchronizer.h"

@protocol SGFFOutput;
@protocol SGFFOutputDelegate;

@protocol SGFFOutput <NSObject>

- (SGMediaType)mediaType;

@property (nonatomic, weak) id <SGFFOutputDelegate> delegate;
@property (nonatomic, strong) SGFFTimeSynchronizer * timeSynchronizer;

- (CMTime)duration;
- (long long)size;
- (NSUInteger)count;

- (void)start;
- (void)stop;

- (void)putFrame:(__kindof SGFFFrame *)frame;
- (void)flush;

@end

@protocol SGFFOutputDelegate <NSObject>

- (void)outputDidChangeCapacity:(id <SGFFOutput>)output;

@end

#endif /* SGFFOutput_h */
