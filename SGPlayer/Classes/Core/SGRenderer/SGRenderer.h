//
//  SGRenderer.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#ifndef SGRenderer_h
#define SGRenderer_h

#import <Foundation/Foundation.h>
#import "SGFrame.h"

@protocol SGRendererDelegate;

@protocol SGRenderer <NSObject>

@property (nonatomic, weak) id <SGRendererDelegate> delegate;
@property (nonatomic, assign) BOOL enable;
@property (nonatomic, assign) BOOL key;

- (NSError *)error;
- (BOOL)enough;
- (BOOL)duratioin:(CMTime *)duration size:(int64_t *)size count:(NSUInteger *)count;

- (void)open;
- (void)close;
- (void)pause;
- (void)resume;

- (void)putFrame:(__kindof SGFrame *)frame;
- (void)flush;

@end

@protocol SGRendererDelegate <NSObject>

- (void)outputDidChangeCapacity:(id <SGRenderer>)output;

@end

#endif /* SGRenderer_h */
