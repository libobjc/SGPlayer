//
//  SGCodecpar.h
//  SGPlayer
//
//  Created by Single on 2018/11/15.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGTimeLayout.h"
#import "avcodec.h"

@interface SGCodecpar : NSObject <NSCopying>

@property (nonatomic, readonly) NSArray <SGTimeLayout *> * timeLayouts;
@property (nonatomic, readonly) AVCodecParameters * codecpar;
@property (nonatomic, readonly) AVRational timebase;

- (BOOL)isEqualToCodecpar:(SGCodecpar *)codecpar;

- (void)setTimebase:(AVRational)timebase codecpar:(AVCodecParameters *)codecpar;
- (void)setTimeLayout:(SGTimeLayout *)timeLayout;
- (void)clear;

@end
