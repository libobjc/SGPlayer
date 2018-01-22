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

static int const max_frame_size = 4096;
static int const max_chan = 2;

@interface SGFFAudioPlayer ()

{
    @public
    float * _outData;
}

@property (nonatomic, weak) id <SGFFAudioPlayerDelegate> delegate;

@property (nonatomic, assign) AUGraph graph;
@property (nonatomic, assign) AUNode nodeForConverter;
@property (nonatomic, assign) AUNode nodeForMixer;
@property (nonatomic, assign) AUNode nodeForOutput;
@property (nonatomic, assign) AudioUnit audioUnitForConverter;
@property (nonatomic, assign) AudioUnit audioUnitForMixer;
@property (nonatomic, assign) AudioUnit audioUnitForOutput;

@end

@implementation SGFFAudioPlayer

+ (AudioStreamBasicDescription)defaultAudioStreamBasicDescription
{
    AudioStreamBasicDescription audioStreamBasicDescription;
    UInt32 floatByteSize                          = sizeof(float);
    audioStreamBasicDescription.mBitsPerChannel   = 8 * floatByteSize;
    audioStreamBasicDescription.mBytesPerFrame    = floatByteSize;
    audioStreamBasicDescription.mChannelsPerFrame = 2;
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
    AUGraphStop(self.graph);
    AUGraphUninitialize(self.graph);
    AUGraphClose(self.graph);
    DisposeAUGraph(self.graph);
    if (_outData)
    {
        free(_outData);
        _outData = nil;
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
    
    UInt32 const maximumFramesPerSlice = 4096;
    AudioUnitSetProperty(self.audioUnitForMixer,
                         kAudioUnitProperty_MaximumFramesPerSlice,
                         kAudioUnitScope_Global, 0,
                         &maximumFramesPerSlice,
                         sizeof(maximumFramesPerSlice));
    
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
    if (_outData)
    {
        free(_outData);
        _outData = nil;
    }
    _outData = (float *)calloc(max_frame_size * max_chan, sizeof(float));
}

- (Float64)sampleRate
{
    return self.audioStreamBasicDescription.mSampleRate;
}

- (UInt32)numberOfChannels
{
    return self.audioStreamBasicDescription.mChannelsPerFrame;
}

OSStatus converterInputCallback(void * inRefCon,
                              AudioUnitRenderActionFlags * ioActionFlags,
                              const AudioTimeStamp * inTimeStamp,
                              UInt32 inBusNumber,
                              UInt32 inNumberFrames,
                              AudioBufferList * ioData)
{
    SGFFAudioPlayer * obj = (__bridge SGFFAudioPlayer *)inRefCon;
    
    for (int i = 0; i < ioData->mNumberBuffers; i++)
    {
        memset(ioData->mBuffers[i].mData, 0, ioData->mBuffers[i].mDataByteSize);
    }
    
        [obj.delegate audioManager:obj outputData:obj->_outData numberOfFrames:inNumberFrames numberOfChannels:obj.numberOfChannels];
        
        UInt32 numBytesPerSample = obj.audioStreamBasicDescription.mBitsPerChannel / 8;
        if (numBytesPerSample == 4) {
            float zero = 0.0;
            for (int iBuffer = 0; iBuffer < ioData->mNumberBuffers; iBuffer++) {
                int thisNumChannels = ioData->mBuffers[iBuffer].mNumberChannels;
                for (int iChannel = 0; iChannel < thisNumChannels; iChannel++) {
                    vDSP_vsadd(obj->_outData + iChannel,
                               obj.numberOfChannels,
                               &zero,
                               (float *)ioData->mBuffers[iBuffer].mData,
                               thisNumChannels,
                               inNumberFrames);
                }
            }
        }
        else if (numBytesPerSample == 2)
        {
            float scale = (float)INT16_MAX;
            vDSP_vsmul(obj->_outData, 1, &scale, obj->_outData, 1, inNumberFrames * obj.numberOfChannels);
            
            for (int iBuffer = 0; iBuffer < ioData->mNumberBuffers; iBuffer++) {
                int thisNumChannels = ioData->mBuffers[iBuffer].mNumberChannels;
                for (int iChannel = 0; iChannel < thisNumChannels; iChannel++) {
                    vDSP_vfix16(obj->_outData + iChannel,
                                obj.numberOfChannels,
                                (SInt16 *)ioData->mBuffers[iBuffer].mData + iChannel,
                                thisNumChannels,
                                inNumberFrames);
                }
            }
        }
    
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
