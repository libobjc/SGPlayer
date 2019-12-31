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

@property (nonatomic, readonly) BOOL needsTimePitchNode;

@end

@implementation SGAudioPlayer

+ (AudioComponentDescription)mixerACD
{
    AudioComponentDescription acd;
    acd.componentType = kAudioUnitType_Mixer;
#if SGPLATFORM_TARGET_OS_MAC || TARGET_OS_MACCATALYST
    acd.componentSubType = kAudioUnitSubType_SpatialMixer;
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
    acd.componentSubType = kAudioUnitSubType_DefaultOutput;
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
    UInt32 byteSize = sizeof(float);
    AudioStreamBasicDescription asbd;
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
    
    AudioUnitParameterID mixerParam;
#if SGPLATFORM_TARGET_OS_MAC
    mixerParam = kStereoMixerParam_Volume;
#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    mixerParam = kMultiChannelMixerParam_Volume;
#endif
    AudioUnitGetParameter(_mixerUnit, mixerParam, kAudioUnitScope_Input, 0, &_volume);
    AudioUnitGetParameter(_timePitchUnit, kNewTimePitchParam_Rate, kAudioUnitScope_Global, 0, &_rate);
    AudioUnitGetParameter(_timePitchUnit, kNewTimePitchParam_Pitch, kAudioUnitScope_Global, 0, &_pitch);
    
    [self setAsbd:asbd];
    [self reconnectTimePitchNodeForce:YES];

    AUGraphInitialize(_graph);
}

- (void)destroy
{
    AUGraphStop(_graph);
    AUGraphUninitialize(_graph);
    AUGraphClose(_graph);
    DisposeAUGraph(_graph);
}

- (void)disconnectNodeInput:(AUNode)sourceNode destNode:(AUNode)destNode
{
    UInt32 count = 8;
    AUNodeInteraction interactions[8];
    if (AUGraphGetNodeInteractions(_graph, destNode, &count, interactions) == noErr) {
        for (UInt32 i = 0; i < MIN(count, 8); i++) {
            AUNodeInteraction interaction = interactions[i];
            if (interaction.nodeInteractionType == kAUNodeInteraction_Connection) {
                AUNodeConnection connection = interaction.nodeInteraction.connection;
                if (connection.sourceNode == sourceNode) {
                    AUGraphDisconnectNodeInput(_graph, connection.destNode, connection.destInputNumber);
                    break;
                }
            }
        }
    }
}

- (void)reconnectTimePitchNodeForce:(BOOL)force
{
    BOOL needsTimePitchNode = (_rate != 1.0) || (_pitch != 0.0);
    if (_needsTimePitchNode != needsTimePitchNode || force) {
        _needsTimePitchNode = needsTimePitchNode;
        if (needsTimePitchNode) {
            [self disconnectNodeInput:_mixerNode destNode:_outputNode];
            AUGraphConnectNodeInput(_graph, _mixerNode, 0, _timePitchNode, 0);
            AUGraphConnectNodeInput(_graph, _timePitchNode, 0, _outputNode, 0);
        } else {
            [self disconnectNodeInput:_mixerNode destNode:_timePitchNode];
            [self disconnectNodeInput:_timePitchNode destNode:_outputNode];
            AUGraphConnectNodeInput(_graph, _mixerNode, 0, _outputNode, 0);
        }
        AUGraphUpdate(_graph, NULL);
    }
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
    AudioUnitReset(_mixerUnit, kAudioUnitScope_Global, 0);
    AudioUnitReset(_outputUnit, kAudioUnitScope_Global, 0);
    AudioUnitReset(_timePitchUnit, kAudioUnitScope_Global, 0);
}

#pragma mark - Setter & Getter

- (BOOL)isPlaying
{
    Boolean ret = FALSE;
    AUGraphIsRunning(_graph, &ret);
    return ret == TRUE ? YES : NO;
}

- (void)setVolume:(float)volume
{
    if (_volume == volume) {
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
    if (_rate == rate) {
        return;
    }
    if (AudioUnitSetParameter(_timePitchUnit, kNewTimePitchParam_Rate, kAudioUnitScope_Global, 0, rate, 0) == noErr) {
        _rate = rate;
        [self reconnectTimePitchNodeForce:NO];
    }
}

- (void)setPitch:(float)pitch
{
    if (_pitch == pitch) {
        return;
    }
    if (AudioUnitSetParameter(_timePitchUnit, kNewTimePitchParam_Pitch, kAudioUnitScope_Global, 0, pitch, 0) == noErr) {
        _pitch = pitch;
        [self reconnectTimePitchNodeForce:NO];
    }
}

- (void)setAsbd:(AudioStreamBasicDescription)asbd
{
    UInt32 size = sizeof(AudioStreamBasicDescription);
    AudioUnitPropertyID param = kAudioUnitProperty_StreamFormat;
    if (AudioUnitSetProperty(_mixerUnit, param, kAudioUnitScope_Input, 0, &asbd, size) == noErr &&
        AudioUnitSetProperty(_mixerUnit, param, kAudioUnitScope_Output, 0, &asbd, size) == noErr &&
        AudioUnitSetProperty(_outputUnit, param, kAudioUnitScope_Input, 0, &asbd, size) == noErr &&
        AudioUnitSetProperty(_timePitchUnit, param, kAudioUnitScope_Input, 0, &asbd, size) == noErr &&
        AudioUnitSetProperty(_timePitchUnit, param, kAudioUnitScope_Output, 0, &asbd, size) == noErr) {
        _asbd = asbd;
    } else {
        AudioUnitSetProperty(_mixerUnit, param, kAudioUnitScope_Input, 0, &_asbd, size);
        AudioUnitSetProperty(_mixerUnit, param, kAudioUnitScope_Output, 0, &_asbd, size);
        AudioUnitSetProperty(_outputUnit, param, kAudioUnitScope_Input, 0, &_asbd, size);
        AudioUnitSetProperty(_timePitchUnit, param, kAudioUnitScope_Input, 0, &_asbd, size);
        AudioUnitSetProperty(_timePitchUnit, param, kAudioUnitScope_Output, 0, &_asbd, size);
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
