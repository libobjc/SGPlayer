//
//  SGFFCodecManager.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFCodec.h"

@interface SGFFCodecManager : NSObject

@property (nonatomic, copy, readonly) NSError * error;

- (void)addCodecs:(NSArray <SGFFCodecInfo *> *)codecInfos;

- (void)prepare;

@end
