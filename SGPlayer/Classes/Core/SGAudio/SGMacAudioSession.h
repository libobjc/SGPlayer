//
//  SGMacAudioSession.h
//  audio-mac
//
//  Created by Single on 2017/2/23.
//  Copyright © 2017年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGMacAudioDevice.h"

@interface SGMacAudioSession : NSObject

+ (instancetype)sharedInstance;

- (NSArray <SGMacAudioDevice *> *)devices;
- (SGMacAudioDevice *)currentDevice;

- (double)sampleRate;
- (NSInteger)outputNumberOfChannels;

@end
