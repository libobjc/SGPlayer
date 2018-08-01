//
//  SGFrameQueue.h
//  SGPlayer
//
//  Created by Single on 18/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFrame2.h"

@interface SGFrameQueue2 : NSObject

+ (instancetype)frameQueue;

+ (NSTimeInterval)maxVideoDuration;

+ (NSTimeInterval)sleepTimeIntervalForFull;
+ (NSTimeInterval)sleepTimeIntervalForFullAndPaused;

@property (nonatomic, assign, readonly) int size;
@property (nonatomic, assign, readonly) int packetSize;
@property (nonatomic, assign, readonly) NSUInteger count;
@property (atomic, assign, readonly) NSTimeInterval duration;

@property (nonatomic, assign) NSUInteger minFrameCountForGet;    // default is 1.
@property (nonatomic, assign) BOOL ignoreMinFrameCountForGetLimit;

- (void)putFrame:(__kindof SGFrame2 *)frame;
- (void)putSortFrame:(__kindof SGFrame2 *)frame;
- (__kindof SGFrame2 *)getFrameSync;
- (__kindof SGFrame2 *)getFrameAsync;
- (__kindof SGFrame2 *)getFrameAsyncPosistion:(NSTimeInterval)position discardFrames:(NSMutableArray <__kindof SGFrame2 *> **)discardFrames;
- (NSTimeInterval)getFirstFramePositionAsync;
- (NSMutableArray <__kindof SGFrame2 *> *)discardFrameBeforPosition:(NSTimeInterval)position;

- (void)flush;
- (void)destroy;

@end
