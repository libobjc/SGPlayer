//
//  SGAudioStreamPlayer.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGAudioStreamPlayer.h"
#import "SGPlatform.h"

static int const SGAudioStreamPlayerMaximumFramesPerSlice = 4096;
static int const SGAudioStreamPlayerMaximumChannels = 2;

@interface SGAudioStreamPlayer ()

@property (nonatomic, assign) AUGraph graph;
@property (nonatomic, assign) AUNode nodeForTimePitch;
@property (nonatomic, assign) AUNode nodeForMixer;
@property (nonatomic, assign) AUNode nodeForOutput;
@property (nonatomic, assign) AudioUnit audioUnitForTimePitch;
@property (nonatomic, assign) AudioUnit audioUnitForMixer;
@property (nonatomic, assign) AudioUnit audioUnitForOutput;

@end

@implementation SGAudioStreamPlayer

+ (AudioStreamBasicDescription)defaultASBD
{
    AudioStreamBasicDescription audioStreamBasicDescription;
    UInt32 floatByteSize                          = sizeof(float);
    audioStreamBasicDescription.mBitsPerChannel   = 8 * floatByteSize;
    audioStreamBasicDescription.mBytesPerFrame    = floatByteSize;
    audioStreamBasicDescription.mChannelsPerFrame = SGAudioStreamPlayerMaximumChannels;
    audioStreamBasicDescription.mFormatFlags      = kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved;
    audioStreamBasicDescription.mFormatID         = kAudioFormatLinearPCM;
    audioStreamBasicDescription.mFramesPerPacket  = 1;
    audioStreamBasicDescription.mBytesPerPacket   = audioStreamBasicDescription.mFramesPerPacket * audioStreamBasicDescription.mBytesPerFrame;
    audioStreamBasicDescription.mSampleRate       = 44100.0f;
    return audioStreamBasicDescription;
}

- (instancetype)init
{
    if (self = [super init])
    {
        [self setup];
    }
    return self;
}

- (void)dealloc
{
    [self destory];
}

#pragma mark - Setup/Destory

- (void)setup
{
    NewAUGraph(&_graph);
    
    AudioComponentDescription descriptionForTimePitch;
    descriptionForTimePitch.componentType = kAudioUnitType_FormatConverter;
    descriptionForTimePitch.componentSubType = kAudioUnitSubType_NewTimePitch;
    descriptionForTimePitch.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    AudioComponentDescription descriptionForMixer;
    descriptionForMixer.componentType = kAudioUnitType_Mixer;
#if SGPLATFORM_TARGET_OS_MAC
    descriptionForMixer.componentSubType = kAudioUnitSubType_StereoMixer;
#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    descriptionForMixer.componentSubType = kAudioUnitSubType_MultiChannelMixer;
#endif
    descriptionForMixer.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    AudioComponentDescription descriptionForOutput;
    descriptionForOutput.componentType = kAudioUnitType_Output;
#if SGPLATFORM_TARGET_OS_MAC
    descriptionForOutput.componentSubType = kAudioUnitSubType_DefaultOutput;
#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    descriptionForOutput.componentSubType = kAudioUnitSubType_RemoteIO;
#endif
    descriptionForOutput.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    AUGraphAddNode(self.graph, &descriptionForTimePitch, &_nodeForTimePitch);
    AUGraphAddNode(self.graph, &descriptionForMixer, &_nodeForMixer);
    AUGraphAddNode(self.graph, &descriptionForOutput, &_nodeForOutput);
    AUGraphOpen(self.graph);
    AUGraphConnectNodeInput(self.graph, self.nodeForTimePitch, 0, self.nodeForMixer, 0);
    AUGraphConnectNodeInput(self.graph, self.nodeForMixer, 0, self.nodeForOutput, 0);
    AUGraphNodeInfo(self.graph, self.nodeForTimePitch, &descriptionForTimePitch, &_audioUnitForTimePitch);
    AUGraphNodeInfo(self.graph, self.nodeForMixer, &descriptionForMixer, &_audioUnitForMixer);
    AUGraphNodeInfo(self.graph, self.nodeForOutput, &descriptionForOutput, &_audioUnitForOutput);
    
    AudioUnitSetProperty(self.audioUnitForTimePitch,
                         kAudioUnitProperty_MaximumFramesPerSlice,
                         kAudioUnitScope_Global, 0,
                         &SGAudioStreamPlayerMaximumFramesPerSlice,
                         sizeof(SGAudioStreamPlayerMaximumFramesPerSlice));
    AudioUnitSetProperty(self.audioUnitForMixer,
                         kAudioUnitProperty_MaximumFramesPerSlice,
                         kAudioUnitScope_Global, 0,
                         &SGAudioStreamPlayerMaximumFramesPerSlice,
                         sizeof(SGAudioStreamPlayerMaximumFramesPerSlice));
    AudioUnitSetProperty(self.audioUnitForOutput,
                         kAudioUnitProperty_MaximumFramesPerSlice,
                         kAudioUnitScope_Global, 0,
                         &SGAudioStreamPlayerMaximumFramesPerSlice,
                         sizeof(SGAudioStreamPlayerMaximumFramesPerSlice));
    
    AURenderCallbackStruct inputCallbackStruct;
    inputCallbackStruct.inputProc = inputCallback;
    inputCallbackStruct.inputProcRefCon = (__bridge void *)(self);
    AUGraphSetNodeInputCallback(self.graph, self.nodeForTimePitch, 0, &inputCallbackStruct);
    AudioUnitAddRenderNotify(self.audioUnitForOutput, outputRenderCallback, (__bridge void *)(self));
    
    NSError * error;
    if (![self setAsbd:[SGAudioStreamPlayer defaultASBD] error:&error])
    {
       _error = error;
        [self callbackForFailed];
    }
    if (![self setVolume:1.0 error:&error])
    {
        _error = error;
        [self callbackForFailed];
    }
    if (![self setRate:1.0 error:&error])
    {
        _error = error;
        [self callbackForFailed];
    }
    AUGraphInitialize(self.graph);
}

- (void)destory
{
    AUGraphStop(self.graph);
    AUGraphUninitialize(self.graph);
    AUGraphClose(self.graph);
    DisposeAUGraph(self.graph);
}

#pragma mark - Interface

- (void)play
{
    if (!self.playing)
    {
        _playing = YES;
        AUGraphStart(self.graph);
    }
}

- (void)pause
{
    if (self.playing)
    {
        _playing = NO;
        AUGraphStop(self.graph);
    }
}

#pragma mark - Setter/Getter

- (BOOL)setVolume:(float)volume error:(NSError **)error
{
    AudioUnitParameterID param;
#if SGPLATFORM_TARGET_OS_MAC
    param = kStereoMixerParam_Volume;
#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    param = kMultiChannelMixerParam_Volume;
#endif
    OSStatus status = AudioUnitSetParameter(self.audioUnitForMixer, param, kAudioUnitScope_Input, 0, volume, 0);
    if (status != noErr)
    {
        * error = [NSError errorWithDomain:@"Volume-Mixer-Global" code:status userInfo:nil];
        return NO;
    }
    _volume = volume;
    return YES;
}

- (BOOL)setRate:(float)rate error:(NSError **)error
{
    OSStatus status = AudioUnitSetParameter(self.audioUnitForTimePitch, kNewTimePitchParam_Rate, kAudioUnitScope_Global, 0, rate, 0);
    if (status != noErr)
    {
        * error = [NSError errorWithDomain:@"Rate-TimePitch-Global" code:status userInfo:nil];
        return NO;
    }
    _rate = rate;
    return YES;
}

- (BOOL)setAsbd:(AudioStreamBasicDescription)asbd error:(NSError **)error
{
    OSStatus status = noErr;
    UInt32 size = sizeof(AudioStreamBasicDescription);
    status = AudioUnitSetProperty(self.audioUnitForTimePitch, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &asbd, size);
    if (status != noErr)
    {
        [self asbdRollback];
        * error = [NSError errorWithDomain:@"StreamForamt-TimePitch-Input" code:status userInfo:nil];
        return NO;
    }
    status = AudioUnitSetProperty(self.audioUnitForTimePitch, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &asbd, size);
    if (status != noErr)
    {
        [self asbdRollback];
        * error = [NSError errorWithDomain:@"StreamForamt-TimePitch-Output" code:status userInfo:nil];
        return NO;
    }
    status = AudioUnitSetProperty(self.audioUnitForMixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &asbd, size);
    if (status != noErr)
    {
        [self asbdRollback];
        * error = [NSError errorWithDomain:@"StreamForamt-Mixer-Input" code:status userInfo:nil];
        return NO;
    }
    status = AudioUnitSetProperty(self.audioUnitForMixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &asbd, size);
    if (status != noErr)
    {
        [self asbdRollback];
        * error = [NSError errorWithDomain:@"StreamForamt-Mixer-Output" code:status userInfo:nil];
        return NO;
    }
    status = AudioUnitSetProperty(self.audioUnitForOutput, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &asbd, size);
    if (status != noErr)
    {
        [self asbdRollback];
        * error = [NSError errorWithDomain:@"StreamForamt-Ouput-Input" code:status userInfo:nil];
        return NO;
    }
    _asbd = asbd;
    return YES;
}

- (void)asbdRollback
{
    UInt32 size = sizeof(AudioStreamBasicDescription);
    AudioUnitSetProperty(self.audioUnitForTimePitch, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &_asbd, size);
    AudioUnitSetProperty(self.audioUnitForTimePitch, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &_asbd, size);
    AudioUnitSetProperty(self.audioUnitForMixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &_asbd, size);
    AudioUnitSetProperty(self.audioUnitForMixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &_asbd, size);
    AudioUnitSetProperty(self.audioUnitForOutput, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &_asbd, size);
    AudioUnitSetProperty(self.audioUnitForOutput, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &_asbd, size);
}

#pragma mark - Callback

- (void)callbackForFailed
{
    if ([self.delegate respondsToSelector:@selector(audioStreamPlayerDidFailed:)])
    {
        [self.delegate audioStreamPlayerDidFailed:self];
    }
}

OSStatus inputCallback(void * inRefCon,
                       AudioUnitRenderActionFlags * ioActionFlags,
                       const AudioTimeStamp * inTimeStamp,
                       UInt32 inBusNumber,
                       UInt32 inNumberFrames,
                       AudioBufferList * ioData)
{
    SGAudioStreamPlayer * obj = (__bridge SGAudioStreamPlayer *)inRefCon;
    for (int i = 0; i < ioData->mNumberBuffers; i++)
    {
        memset(ioData->mBuffers[i].mData, 0, ioData->mBuffers[i].mDataByteSize);
    }
    [obj.delegate audioPlayer:obj inputSample:inTimeStamp ioData:ioData numberOfSamples:inNumberFrames];
    return noErr;
}

OSStatus outputRenderCallback(void * inRefCon,
                              AudioUnitRenderActionFlags * ioActionFlags,
                              const AudioTimeStamp * inTimeStamp,
                              UInt32 inBusNumber,
                              UInt32 inNumberFrames,
                              AudioBufferList * ioData)
{
    SGAudioStreamPlayer * obj = (__bridge SGAudioStreamPlayer *)inRefCon;
    if ((* ioActionFlags) & kAudioUnitRenderAction_PreRender)
    {
        if ([obj.delegate respondsToSelector:@selector(audioStreamPlayer:prepareSample:)])
        {
            [obj.delegate audioStreamPlayer:obj prepareSample:inTimeStamp];
        }
    }
    else if ((* ioActionFlags) & kAudioUnitRenderAction_PostRender)
    {
        if ([obj.delegate respondsToSelector:@selector(audioStreamPlayer:postSample:)])
        {
            [obj.delegate audioStreamPlayer:obj postSample:inTimeStamp];
        }
    }
    return noErr;
}

@end
