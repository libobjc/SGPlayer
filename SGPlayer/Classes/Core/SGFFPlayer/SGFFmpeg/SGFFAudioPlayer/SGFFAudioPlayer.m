//
//  SGFFAudioPlayer.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFAudioPlayer.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>
#import "SGPlatform.h"

static int const SGFFAudioPlayerMaximumFramesPerSlice = 4096;
static int const SGFFAudioPlayerMaximumChannels = 2;

@interface SGFFAudioPlayer ()

@property (nonatomic, weak) id <SGFFAudioPlayerDelegate> delegate;

@property (nonatomic, assign) AUGraph graph;
@property (nonatomic, assign) AUNode nodeForConverter;
@property (nonatomic, assign) AUNode nodeForMixer;
@property (nonatomic, assign) AUNode nodeForOutput;
@property (nonatomic, assign) AudioUnit audioUnitForConverter;
@property (nonatomic, assign) AudioUnit audioUnitForMixer;
@property (nonatomic, assign) AudioUnit audioUnitForOutput;
@property (nonatomic, assign) AudioStreamBasicDescription audioStreamBasicDescription;
@property (nonatomic, assign) float * outputData;

@end

@implementation SGFFAudioPlayer

+ (AudioStreamBasicDescription)defaultAudioStreamBasicDescription
{
    AudioStreamBasicDescription audioStreamBasicDescription;
    UInt32 floatByteSize                          = sizeof(float);
    audioStreamBasicDescription.mBitsPerChannel   = 8 * floatByteSize;
    audioStreamBasicDescription.mBytesPerFrame    = floatByteSize;
    audioStreamBasicDescription.mChannelsPerFrame = SGFFAudioPlayerMaximumChannels;
    audioStreamBasicDescription.mFormatFlags      = kAudioFormatFlagIsFloat|kAudioFormatFlagIsNonInterleaved;
    audioStreamBasicDescription.mFormatID         = kAudioFormatLinearPCM;
    audioStreamBasicDescription.mFramesPerPacket  = 1;
    audioStreamBasicDescription.mBytesPerPacket   = audioStreamBasicDescription.mFramesPerPacket
    * audioStreamBasicDescription.mBytesPerFrame;
    audioStreamBasicDescription.mSampleRate       = 44100.0f;
    return audioStreamBasicDescription;
}

- (instancetype)initWithDelegate:(id<SGFFAudioPlayerDelegate>)delegate
{
    if (self = [super init])
    {
        self.delegate = delegate;
        [self setupAUGraph];
    }
    return self;
}

- (void)dealloc
{
    [self stop];
    if (self.outputData)
    {
        free(self.outputData);
        self.outputData = nil;
    }
}

- (void)setupAUGraph
{
    NewAUGraph(&_graph);
    
    AudioComponentDescription descriptionForConverter;
    descriptionForConverter.componentType = kAudioUnitType_FormatConverter;
    descriptionForConverter.componentSubType = kAudioUnitSubType_AUConverter;
    descriptionForConverter.componentManufacturer = kAudioUnitManufacturer_Apple;
    AUGraphAddNode(self.graph, &descriptionForConverter, &_nodeForConverter);
    
    AudioComponentDescription descriptionForMixer;
    descriptionForMixer.componentType = kAudioUnitType_Mixer;
#if SGPLATFORM_TARGET_OS_MAC
    descriptionForMixer.componentSubType = kAudioUnitSubType_StereoMixer;
#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    descriptionForMixer.componentSubType = kAudioUnitSubType_MultiChannelMixer;
#endif
    descriptionForMixer.componentManufacturer = kAudioUnitManufacturer_Apple;
    AUGraphAddNode(self.graph, &descriptionForMixer, &_nodeForMixer);
    
    AudioComponentDescription descriptionForOutput;
    descriptionForOutput.componentType = kAudioUnitType_Output;
#if SGPLATFORM_TARGET_OS_MAC
    descriptionForOutput.componentSubType = kAudioUnitSubType_DefaultOutput;
#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    descriptionForOutput.componentSubType = kAudioUnitSubType_RemoteIO;
#endif
    descriptionForOutput.componentManufacturer = kAudioUnitManufacturer_Apple;
    AUGraphAddNode(self.graph, &descriptionForOutput, &_nodeForOutput);
    
    AUGraphOpen(self.graph);
    
    AUGraphConnectNodeInput(self.graph, self.nodeForConverter, 0, self.nodeForMixer, 0);
    AUGraphConnectNodeInput(self.graph, self.nodeForMixer, 0, self.nodeForOutput, 0);
    
    AUGraphNodeInfo(self.graph, self.nodeForConverter, &descriptionForConverter, &_audioUnitForConverter);
    AUGraphNodeInfo(self.graph, self.nodeForMixer, &descriptionForMixer, &_audioUnitForMixer);
    AUGraphNodeInfo(self.graph, self.nodeForOutput, &descriptionForOutput, &_audioUnitForOutput);
    
    AURenderCallbackStruct callbackForConverter;
    callbackForConverter.inputProc = converterInputCallback;
    callbackForConverter.inputProcRefCon = (__bridge void *)(self);
    AUGraphSetNodeInputCallback(self.graph, self.nodeForConverter, 0, &callbackForConverter);
    AudioUnitAddRenderNotify(self.audioUnitForOutput, outputRenderCallback, (__bridge void *)(self));
    
    self.audioStreamBasicDescription = [SGFFAudioPlayer defaultAudioStreamBasicDescription];
    
    AudioUnitSetProperty(self.audioUnitForMixer,
                         kAudioUnitProperty_MaximumFramesPerSlice,
                         kAudioUnitScope_Global, 0,
                         &SGFFAudioPlayerMaximumFramesPerSlice,
                         sizeof(SGFFAudioPlayerMaximumFramesPerSlice));
    
    AUGraphInitialize(self.graph);
}

- (void)play
{
    AUGraphStart(self.graph);
}

- (void)pause
{
    AUGraphStop(self.graph);
}

- (void)stop
{
    AUGraphStop(self.graph);
    AUGraphUninitialize(self.graph);
    AUGraphClose(self.graph);
    DisposeAUGraph(self.graph);
}

- (void)setAudioStreamBasicDescription:(AudioStreamBasicDescription)audioStreamBasicDescription
{
    _audioStreamBasicDescription = audioStreamBasicDescription;
    UInt32 audioStreamBasicDescriptionSize = sizeof(AudioStreamBasicDescription);
    AudioUnitSetProperty(self.audioUnitForConverter,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Input, 0,
                         &_audioStreamBasicDescription,
                         audioStreamBasicDescriptionSize);
    AudioUnitSetProperty(self.audioUnitForConverter,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Output, 0,
                         &_audioStreamBasicDescription,
                         audioStreamBasicDescriptionSize);
    AudioUnitSetProperty(self.audioUnitForMixer,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Input, 0,
                         &_audioStreamBasicDescription,
                         audioStreamBasicDescriptionSize);
    AudioUnitSetProperty(self.audioUnitForMixer,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Output, 0,
                         &_audioStreamBasicDescription,
                         audioStreamBasicDescriptionSize);
    if (self.outputData)
    {
        free(self.outputData);
        self.outputData = nil;
    }
    self.outputData = (float *)calloc(SGFFAudioPlayerMaximumFramesPerSlice * SGFFAudioPlayerMaximumChannels, sizeof(float));
}

- (int)sampleRate
{
    return (int)self.audioStreamBasicDescription.mSampleRate;
}

- (int)numberOfChannels
{
    return (int)self.audioStreamBasicDescription.mChannelsPerFrame;
}

- (void)converterInputCallback:(AudioBufferList *)ioData inNumberFrames:(UInt32)inNumberFrames
{
    for (int i = 0; i < ioData->mNumberBuffers; i++)
    {
        memset(ioData->mBuffers[i].mData, 0, ioData->mBuffers[i].mDataByteSize);
    }
    [self.delegate audioPlayer:self outputData:self.outputData numberOfSamples:inNumberFrames numberOfChannels:self.numberOfChannels];
    for (int i = 0; i < ioData->mNumberBuffers; i++)
    {
        float zero = 0.0;
        int currentNumberOfChannels = ioData->mBuffers[i].mNumberChannels;
        vDSP_vsadd(self.outputData + i,
                   self.numberOfChannels,
                   &zero,
                   (float *)ioData->mBuffers[i].mData,
                   currentNumberOfChannels,
                   inNumberFrames);
    }
}

OSStatus converterInputCallback(void * inRefCon,
                                AudioUnitRenderActionFlags * ioActionFlags,
                                const AudioTimeStamp * inTimeStamp,
                                UInt32 inBusNumber,
                                UInt32 inNumberFrames,
                                AudioBufferList * ioData)
{
    SGFFAudioPlayer * obj = (__bridge SGFFAudioPlayer *)inRefCon;
    [obj converterInputCallback:ioData inNumberFrames:inNumberFrames];
    return noErr;
}

OSStatus outputRenderCallback(void * inRefCon,
                              AudioUnitRenderActionFlags * ioActionFlags,
                              const AudioTimeStamp * inTimeStamp,
                              UInt32 inBusNumber,
                              UInt32 inNumberFrames,
                              AudioBufferList * ioData)
{
    SGFFAudioPlayer * obj = (__bridge SGFFAudioPlayer *)inRefCon;
    NSLog(@"%@", obj);
    return noErr;
}

@end
