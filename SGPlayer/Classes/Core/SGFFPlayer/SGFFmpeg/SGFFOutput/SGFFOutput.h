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

@property (nonatomic, weak) id <SGFFOutputRenderSource> renderSource;

- (id <SGFFOutputRender>)renderWithFrame:(id <SGFFFrame>)frame;
- (SGFFTime)currentTime;

- (void)play;
- (void)pause;

@end

@protocol SGFFOutputRenderSource <NSObject>

- (id <SGFFOutputRender>)outputFecthRender:(id <SGFFOutput>)output;
- (id <SGFFOutputRender>)outputFecthRender:(id <SGFFOutput>)output
                           currentPosition:(long long)currentPosition
                            expectPosition:(long long)expectPosition;

@end


#endif /* SGFFOutput_h */
