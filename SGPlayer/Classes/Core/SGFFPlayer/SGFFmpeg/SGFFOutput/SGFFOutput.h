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
#import "SGFFSync.h"
#import "SGFFOutputRender.h"


@protocol SGFFOutput;
@protocol SGFFOutputRenderDelegate;
@protocol SGFFOutputRenderSource;


@protocol SGFFOutput <NSObject>

@property (nonatomic, weak) id <SGFFOutputRenderDelegate> renderDelegate;
@property (nonatomic, weak) id <SGFFOutputRenderSource> renderSource;
- (id <SGFFOutputRender>)renderWithFrame:(id <SGFFFrame>)frame;

- (SGFFTime)currentTime;

- (void)play;
- (void)pause;

@end


@protocol SGFFOutputRenderDelegate <NSObject>

- (void)outputDidUpdateCurrentTime:(id <SGFFOutput>)output;

@end

@protocol SGFFOutputRenderSource <NSObject>

- (id <SGFFOutputRender>)outputFecthRender:(id <SGFFOutput>)output;

@end


#endif /* SGFFOutput_h */
