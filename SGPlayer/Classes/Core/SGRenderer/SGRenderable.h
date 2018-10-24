//
//  SGRenderable.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#ifndef SGRenderable_h
#define SGRenderable_h

#import <Foundation/Foundation.h>
#import "SGFrame.h"

@protocol SGRenderableDelegate;

typedef NS_ENUM(NSUInteger, SGRenderableState)
{
    SGRenderableStateNone,
    SGRenderableStateRendering,
    SGRenderableStatePaused,
    SGRenderableStateClosed,
    SGRenderableStateFailed,
};

@protocol SGRenderable <NSObject>

@property (nonatomic, weak) id object;
@property (nonatomic, weak) id <SGRenderableDelegate> delegate;
@property (nonatomic, assign) BOOL key;

- (SGRenderableState)state;
- (NSError *)error;
- (BOOL)enough;
- (BOOL)duratioin:(CMTime *)duration size:(int64_t *)size count:(NSUInteger *)count;

- (BOOL)open;
- (BOOL)close;
- (BOOL)pause;
- (BOOL)resume;

- (BOOL)putFrame:(__kindof SGFrame *)frame;
- (BOOL)flush;

@end

@protocol SGRenderableDelegate <NSObject>

- (void)renderable:(id <SGRenderable>)renderable didRenderFrame:(__kindof SGFrame *)frame;
- (void)renderable:(id <SGRenderable>)renderable didChangeState:(SGRenderableState)state;
- (void)renderable:(id <SGRenderable>)renderable didChangeDuration:(CMTime)duration size:(int64_t)size count:(NSUInteger)count;

@end

#endif /* SGRenderable_h */
