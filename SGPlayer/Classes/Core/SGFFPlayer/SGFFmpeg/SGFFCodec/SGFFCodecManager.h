//
//  SGFFCodecManager.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFStream.h"

@class SGFFCodecManager;

@protocol SGFFCodecManagerDelegate <NSObject>

- (void)codecManagerDidOpened:(SGFFCodecManager *)codecManager;
- (void)codecManagerDidFailed:(SGFFCodecManager *)codecManager;

@end

@interface SGFFCodecManager : NSObject

- (instancetype)initWithStreams:(NSArray <SGFFStream *> *)streams delegate:(id <SGFFCodecManagerDelegate>)delegate;

- (NSError *)error;

- (void)open;

@end
