//
//  SGAudioPlayer.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGAudioPlayer.h"
#import "SGPLFTargets.h"

@interface SGAudioPlayer ()

{
    AUGraph _graph;
    AUNode _mixerNode;
    AUNode _outputNode;
    AUNode _timePitchNode;
    AudioUnit _mixerUnit;
    AudioUnit _outputUnit;
    AudioUnit _timePitchUnit;
}

@end

@implementation SGAudioPlayer

+ (AudioComponentDescription)mixerACD
{
    AudioComponentDescription acd;
    acd.componentType = kAudioUnitType_Mixer;
#if SGPLATFORM_TARGET_OS_MAC
    acd.componentSubType = kAudioUnitSubType_StereoMixer;
#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    acd.componentSubType = kAudioUnitSubType_MultiChannelMixer;
#endif
    acd.componentManufacturer = kAudioUnitManufacturer_Apple;
    return acd;
}

+ (AudioComponentDescription)outputACD
{
    AudioComponentDescription acd;
    acd.componentType = kAudioUnitType_Output;
#if SGPLATFORM_TARGET_OS_MAC
    acd.componentSuype = kAudioUnitSubType_DefaultOutput;
#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    acd.componentSubType = kAudioUnitSubType_RemoteIO;
#endif
    acd.componentManufacturer = kAudioUnitManufacturer_Apple;
    return acd;
}

+ (AudioComponentDescription)timePitchACD
{
    AudioComponentDescription acd;
    acd.componentType = kAudioUnitType_FormatConverter;
    acd.componentSubType = kAudioUnitSubType_NewTimePitch;
    acd.componentManufacturer = kAudioUnitManufacturer_Apple;
    return acd;
}

+ (AudioStreamBasicDescription)commonASBD
{
    AudioStreamBasicDescription asbd;
    UInt32 byteSize   = sizeof(float);
    asbd.mBitsPerChannel   = byteSize * 8;
    asbd.mBytesPerFrame    = byteSize;
    asbd.mChannelsPerFrame = 2;
    asbd.mFormatFlags      = kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved;
    asbd.mFormatID         = kAudioFormatLinearPCM;
    asbd.mFramesPerPacket  = 1;
    asbd.mBytesPerPacket   = asbd.mFramesPerPacket * asbd.mBytesPerFrame;
    asbd.mSampleRate       = 44100.0f;
    return asbd;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)dealloc
{
    [self destroy];
}

#pragma mark - Setup/Destory

- (void)setup
{
    AudioStreamBasicDescription asbd = [self.class commonASBD];
    AudioComponentDescription mixerACD = [self.class mixerACD];
    AudioComponentDescription outputACD = [self.class outputACD];
    AudioComponentDescription timePitchACD = [self.class timePitchACD];
    
    NewAUGraph(&_graph);
    AUGraphAddNode(_graph, &mixerACD, &_mixerNode);
    AUGraphAddNode(_graph, &outputACD, &_outputNode);
    AUGraphAddNode(_graph, &timePitchACD, &_timePitchNode);
    AUGraphOpen(_graph);
    
    AUGraphConnectNodeInput(_graph, _mixerNode, 0, _timePitchNode, 0);
    AUGraphConnectNodeInput(_graph, _timePitchNode, 0, _outputNode, 0);
    
    AUGraphNodeInfo(_graph, _mixerNode, &mixerACD, &_mixerUnit);
    AUGraphNodeInfo(_graph, _outputNode, &outputACD, &_outputUnit);
    AUGraphNodeInfo(_graph, _timePitchNode, &timePitchACD, &_timePitchUnit);
    
    UInt32 value = 4096;
    UInt32 size = sizeof(value);
    AudioUnitScope scope = kAudioUnitScope_Global;
    AudioUnitPropertyID param = kAudioUnitProperty_MaximumFramesPerSlice;
    AudioUnitSetProperty(_mixerUnit, param, scope, 0, &value, size);
    AudioUnitSetProperty(_outputUnit, param, scope, 0, &value, size);
    AudioUnitSetProperty(_timePitchUnit, param, scope, 0, &value, size);
    
    AURenderCallbackStruct inputCallbackStruct;
    inputCallbackStruct.inputProc = inputCallback;
    inputCallbackStruct.inputProcRefCon = (__bridge void *)self;
    AUGraphSetNodeInputCallback(_graph, _mixerNode, 0, &inputCallbackStruct);
    AudioUnitAddRenderNotify(_outputUnit, outputCallback, (__bridge void *)self);
    
    _rate = 1.0;
    _volume = 1.0;
    [self setAsbd:asbd];

    AUGraphInitialize(_graph);
}

- (void)destroy
{
    AUGraphStop(_graph);
    AUGraphUninitialize(_graph);
    AUGraphClose(_graph);
    DisposeAUGraph(_graph);
}

#pragma mark - Interface

- (void)play
{
    if ([self isPlaying] == NO) {
        AUGraphStart(_graph);
    }
}

- (void)pause
{
    if ([self isPlaying] == YES) {
        AUGraphStop(_graph);
    }
}

- (void)flush
{
    if (_mixerUnit) {
        AudioUnitReset(_mixerUnit, kAudioUnitScope_Global, 0);
    }
    if (_outputUnit) {
        AudioUnitReset(_outputUnit, kAudioUnitScope_Global, 0);
    }
    if (_timePitchUnit) {
        AudioUnitReset(_timePitchUnit, kAudioUnitScope_Global, 0);
    }
}

#pragma mark - Setter & Getter

- (BOOL)isPlaying
{
    if (!_graph) {
        return NO;
    }
    Boolean ret = FALSE;
    AUGraphIsRunning(_graph, &ret);
    return ret == TRUE ? YES : NO;
}

- (void)setVolume:(float)volume
{
    if (!_mixerUnit) {
        return;
    }
    AudioUnitParameterID param;
#if SGPLATFORM_TARGET_OS_MAC
    param = kStereoMixerParam_Volume;
#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    param = kMultiChannelMixerParam_Volume;
#endif
    if (AudioUnitSetParameter(_mixerUnit, param, kAudioUnitScope_Input, 0, volume, 0) == noErr) {
        _volume = volume;
    }
}

- (void)setRate:(float)rate
{
    if (!_timePitchUnit) {
        return;
    }
    if (AudioUnitSetParameter(_timePitchUnit, kNewTimePitchParam_Rate, kAudioUnitScope_Global, 0, rate, 0) == noErr) {
        _rate = rate;
    }
}

- (void)setAsbd:(AudioStreamBasicDescription)asbd
{
    UInt32 size = sizeof(AudioStreamBasicDescription);
    AudioUnitScope scope = kAudioUnitScope_Global;
    AudioUnitPropertyID param = kAudioUnitProperty_StreamFormat;
    BOOL success = YES;
    if (success && _mixerUnit) {
        success &= AudioUnitSetProperty(_mixerUnit, param, scope, 0, &asbd, size) == noErr;
    }
    if (success && _outputUnit) {
        success &= AudioUnitSetProperty(_mixerUnit, param, scope, 0, &asbd, size) == noErr;
    }
    if (success && _timePitchUnit) {
        success &= AudioUnitSetProperty(_mixerUnit, param, scope, 0, &asbd, size) == noErr;
    }
    if (success) {
        _asbd = asbd;
    } else {
        if (_mixerUnit) {
            AudioUnitSetProperty(_mixerUnit, param, scope, 0, &_asbd, size);
        }
        if (_outputUnit) {
            AudioUnitSetProperty(_outputUnit, param, scope, 0, &_asbd, size);
        }
        if (_timePitchUnit) {
            AudioUnitSetProperty(_timePitchUnit, param, scope, 0, &_asbd, size);
        }
    }
}

#pragma mark - Callback

static OSStatus inputCallback(void *inRefCon,
                              AudioUnitRenderActionFlags *ioActionFlags,
                              const AudioTimeStamp *inTimeStamp,
                              UInt32 inBusNumber,
                              UInt32 inNumberFrames,
                              AudioBufferList *ioData)
{
    @autoreleasepool {
        SGAudioPlayer *self = (__bridge SGAudioPlayer *)inRefCon;
        [self.delegate audioPlayer:self render:inTimeStamp data:ioData numberOfFrames:inNumberFrames];
    }
    return noErr;
}

static OSStatus outputCallback(void *inRefCon,
                               AudioUnitRenderActionFlags *ioActionFlags,
                               const AudioTimeStamp *inTimeStamp,
                               UInt32 inBusNumber,
                               UInt32 inNumberFrames,
                               AudioBufferList *ioData)
{
    @autoreleasepool {
        SGAudioPlayer *self = (__bridge SGAudioPlayer *)inRefCon;
        if ((*ioActionFlags) & kAudioUnitRenderAction_PreRender) {
            if ([self.delegate respondsToSelector:@selector(audioPlayer:willRender:)]) {
                [self.delegate audioPlayer:self willRender:inTimeStamp];
            }
        } else if ((*ioActionFlags) & kAudioUnitRenderAction_PostRender) {
            if ([self.delegate respondsToSelector:@selector(audioPlayer:didRender:)]) {
                [self.delegate audioPlayer:self didRender:inTimeStamp];
            }
        }
    }
    return noErr;
}

@end
