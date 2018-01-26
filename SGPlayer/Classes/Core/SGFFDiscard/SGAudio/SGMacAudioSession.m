//
//  SGMacAudioSession.m
//  SGPlayer
//
//  Created by Single on 2017/2/23.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGMacAudioSession.h"
#import <AudioToolbox/AudioToolbox.h>

@implementation SGMacAudioSession

+ (instancetype)sharedInstance
{
    static SGMacAudioSession * audioSession = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        audioSession = [[SGMacAudioSession alloc] init];
    });
    return audioSession;
}

- (double)sampleRate
{
    return 44100;
}

- (NSInteger)outputNumberOfChannels
{
    return self.currentDevice.outputChannelCount;
}

- (NSArray<SGMacAudioDevice *> *)devices
{
    return [self audioDevicesForPropertySelector:kAudioHardwarePropertyDevices];
}

- (SGMacAudioDevice *)currentDevice
{
    return [self audioDevicesForPropertySelector:kAudioHardwarePropertyDefaultOutputDevice].firstObject;
}

- (NSArray<SGMacAudioDevice *> *)audioDevicesForPropertySelector:(AudioObjectPropertySelector)selector
{
    NSMutableArray * devices = [NSMutableArray array];
    
    AudioObjectPropertyAddress address = [self addressForPropertySelector:selector];
    UInt32 devicesDataSize;
    [self checkResult:AudioObjectGetPropertyDataSize(kAudioObjectSystemObject,
                                                                 &address,
                                                                 0,
                                                                 NULL,
                                                                 &devicesDataSize)
            operation:"Failed to get data size"];
    
    NSInteger count = devicesDataSize / sizeof(AudioDeviceID);
    AudioDeviceID * deviceIDs = (AudioDeviceID *)malloc(devicesDataSize);
    
    [self checkResult:AudioObjectGetPropertyData(kAudioObjectSystemObject,
                                                             &address,
                                                             0,
                                                             NULL,
                                                             &devicesDataSize,
                                                             deviceIDs)
            operation:"Failed to get device IDs for available devices on OSX"];
    
    for (UInt32 i = 0; i < count; i++)
    {
        AudioDeviceID deviceID = deviceIDs[i];
        SGMacAudioDevice * device = [[SGMacAudioDevice alloc] init];
        device.deviceID = deviceID;
        device.manufacturer = [self manufacturerForDeviceID:deviceID];
        device.name = [self namePropertyForDeviceID:deviceID];
        device.UID = [self UIDPropertyForDeviceID:deviceID];
        device.inputChannelCount = [self channelCountForScope:kAudioObjectPropertyScopeInput forDeviceID:deviceID];
        device.outputChannelCount = [self channelCountForScope:kAudioObjectPropertyScopeOutput forDeviceID:deviceID];
        [devices addObject:device];
    }
    
    free(deviceIDs);
    
    return devices;
}

- (AudioObjectPropertyAddress)addressForPropertySelector:(AudioObjectPropertySelector)selector
{
    AudioObjectPropertyAddress address;
    address.mScope = kAudioObjectPropertyScopeGlobal;
    address.mElement = kAudioObjectPropertyElementMaster;
    address.mSelector = selector;
    return address;
}

- (NSString *)stringPropertyForSelector:(AudioObjectPropertySelector)selector
                           withDeviceID:(AudioDeviceID)deviceID
{
    AudioObjectPropertyAddress address = [self addressForPropertySelector:selector];
    CFStringRef string;
    UInt32 propSize = sizeof(CFStringRef);
    NSString *errorString = [NSString stringWithFormat:@"Failed to get device property (%u)",(unsigned int)selector];
    [self checkResult:AudioObjectGetPropertyData(deviceID,
                                                             &address,
                                                             0,
                                                             NULL,
                                                             &propSize,
                                                             &string)
                        operation:errorString.UTF8String];
    return (__bridge_transfer NSString *)string;
}

- (NSInteger)channelCountForScope:(AudioObjectPropertyScope)scope
                      forDeviceID:(AudioDeviceID)deviceID
{
    AudioObjectPropertyAddress address;
    address.mScope = scope;
    address.mElement = kAudioObjectPropertyElementMaster;
    address.mSelector = kAudioDevicePropertyStreamConfiguration;
    
    AudioBufferList streamConfiguration;
    UInt32 propSize = sizeof(streamConfiguration);
    [self checkResult:AudioObjectGetPropertyData(deviceID,
                                                             &address,
                                                             0,
                                                             NULL,
                                                             &propSize,
                                                             &streamConfiguration)
                        operation:"Failed to get frame size"];
    
    NSInteger channelCount = 0;
    for (NSInteger i = 0; i < streamConfiguration.mNumberBuffers; i++)
    {
        channelCount += streamConfiguration.mBuffers[i].mNumberChannels;
    }
    
    return channelCount;
}

- (NSString *)manufacturerForDeviceID:(AudioDeviceID)deviceID
{
    return [self stringPropertyForSelector:kAudioDevicePropertyDeviceManufacturerCFString
                              withDeviceID:deviceID];
}

- (NSString *)namePropertyForDeviceID:(AudioDeviceID)deviceID
{
    return [self stringPropertyForSelector:kAudioDevicePropertyDeviceNameCFString
                              withDeviceID:deviceID];
}

- (NSString *)UIDPropertyForDeviceID:(AudioDeviceID)deviceID
{
    return [self stringPropertyForSelector:kAudioDevicePropertyDeviceUID
                              withDeviceID:deviceID];
}

- (void)checkResult:(OSStatus)result operation:(const char *)operation
{
    if (result == noErr) return;
    char errorString[20];
    // see if it appears to be a 4-char-code
    *(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(result);
    if (isprint(errorString[1]) && isprint(errorString[2]) && isprint(errorString[3]) && isprint(errorString[4]))
    {
        errorString[0] = errorString[5] = '\'';
        errorString[6] = '\0';
    } else
        // no, format it as an integer
        sprintf(errorString, "%d", (int)result);
    fprintf(stderr, "Error: %s (%s)\n", operation, errorString);
}

@end
