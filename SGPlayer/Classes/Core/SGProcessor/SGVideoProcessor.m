//
//  SGVideoProcessor.m
//  SGPlayer
//
//  Created by Single on 2019/8/13.
//  Copyright © 2019 single. All rights reserved.
//

#import "SGVideoProcessor.h"
#import "SGFrame+Internal.h"
#import "SGVideoRenderer.h"
#import "SGSWScale.h"
#import "SGFFmpeg.h"

@interface SGVideoProcessor ()

@property (nonatomic, strong, readonly) SGTrackSelection *selection;
@property (nonatomic, strong, readonly) NSArray<NSNumber *> *supportedPixelFormats;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, SGSWScale *> *scalers;

@end

@implementation SGVideoProcessor

- (void)setSupportedPixelFormats:(NSArray<NSNumber *> *)supportedPixelFormats
{
    self->_supportedPixelFormats = [supportedPixelFormats copy];
}

- (void)setSelection:(SGTrackSelection *)selection action:(SGTrackSelectionAction)action
{
    self->_selection = [selection copy];
    if (action & SGTrackSelectionActionTracks) {
        self->_scalers = [NSMutableDictionary dictionary];
    }
}

- (__kindof SGFrame *)putFrame:(__kindof SGFrame *)frame
{
    if (![frame isKindOfClass:[SGVideoFrame class]] ||
        ![self->_selection.tracks containsObject:frame.track]) {
        [frame unlock];
        return nil;
    }
    if (!self->_supportedPixelFormats) {
        return frame;
    }
    SGVideoFrame *videoFrame = frame;
    BOOL isSupported = NO;
    for (NSNumber *obj in self->_supportedPixelFormats) {
        if (obj.intValue == videoFrame.descriptor.format) {
            isSupported = YES;
        }
    }
    if (isSupported || videoFrame.pixelBuffer) {
        return frame;
    }
    int format = self->_supportedPixelFormats.firstObject.intValue;
    SGSWScale *scaler = self->_scalers[@(frame.track.index)];
    if (![scaler.inputDescriptor isEqualToDescriptor:videoFrame.descriptor]) {
        scaler = [[SGSWScale alloc] init];
        scaler.inputDescriptor = videoFrame.descriptor;
        scaler.outputDescriptor = [videoFrame.descriptor copy];
        scaler.outputDescriptor.format = format;
        if ([scaler open]) {
            self->_scalers[@(frame.track.index)] = scaler;
        } else {
            [frame unlock];
            return nil;
        }
    }
    SGVideoFrame *newFrame = [SGVideoFrame frameWithDescriptor:scaler.outputDescriptor];
    int result = [scaler convert:(void *)videoFrame.data
                   inputLinesize:videoFrame.linesize
                      outputData:newFrame.core->data
                  outputLinesize:newFrame.core->linesize];
    if (result < 0) {
        [newFrame unlock];
        [frame unlock];
        return nil;
    }
    [newFrame setCodecDescriptor:frame.codecDescriptor];
    [newFrame fillWithTimeStamp:frame.timeStamp decodeTimeStamp:frame.decodeTimeStamp duration:frame.duration];
    [frame unlock];
    return newFrame;
}

- (__kindof SGFrame *)finish
{
    return nil;
}

- (SGCapacity)capacity
{
    return SGCapacityCreate();
}

- (void)flush
{

}

- (void)close
{

}

@end
