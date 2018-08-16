//
//  SGOutput.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#ifndef SGOutput_h
#define SGOutput_h

#import <Foundation/Foundation.h>
#import "SGDefines.h"
#import "SGFrame.h"

@protocol SGOutput;
@protocol SGOutputDelegate;

@protocol SGOutput <NSObject>

- (SGMediaType)mediaType;

@property (nonatomic, weak) id <SGOutputDelegate> delegate;
@property (nonatomic, assign) BOOL enable;
@property (nonatomic, assign) BOOL key;

- (NSError *)error;
- (BOOL)empty;
- (CMTime)duration;
- (long long)size;
- (NSUInteger)count;
- (NSUInteger)maxCount;

- (void)open;
- (void)pause;
- (void)resume;
- (void)close;

- (void)putFrame:(__kindof SGFrame *)frame;
- (BOOL)hasFrame;
- (void)flush;

@end

@protocol SGOutputDelegate <NSObject>

- (void)outputDidChangeCapacity:(id <SGOutput>)output;

@end

#endif /* SGOutput_h */
