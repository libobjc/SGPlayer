//
//  SGAudioDevice.h
//  audio-mac
//
//  Created by Single on 2017/2/23.
//  Copyright © 2017年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface SGMacAudioDevice : NSObject

@property (nonatomic, assign) AudioDeviceID deviceID;
@property (nonatomic, copy) NSString * manufacturer;
@property (nonatomic, copy) NSString * name;
@property (nonatomic, assign) NSInteger inputChannelCount;
@property (nonatomic, assign) NSInteger outputChannelCount;
@property (nonatomic, copy) NSString * UID;

@end
