//
//  SGFFVideoVTBCodec.m
//  SGPlayer
//
//  Created by Single on 2018/1/26.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFVideoVTBCodec.h"
#import <VideoToolbox/VideoToolbox.h>
#import "SGFFVideoFrame.h"
#import "SGFFObjectPool.h"

@interface SGFFVideoVTBCodec ()

{
    VTDecompressionSessionRef _decompressionSession;
    CMFormatDescriptionRef _formatDescription;
}

@property (nonatomic, assign) BOOL shouldConvertNALSize3To4;

@end

@implementation SGFFVideoVTBCodec

+ (SGFFCodecType)type
{
    return SGFFCodecTypeVideo;
}

- (NSInteger)outputRenderQueueMaxCount
{
    return 3;
}

- (BOOL)open
{
    if ([self setupDecompressionSession])
    {
        BOOL success = [super open];
        self.outputRenderQueue.shouldSortObjects = YES;
        return success;
    }
    return NO;
}

- (void)close
{
    [super close];
    [self destoryDecompressionSession];
}

- (void)doFlushCodec
{
    [self destoryDecompressionSession];
    [self setupDecompressionSession];
}

- (NSArray <id <SGFFFrame>> *)doDecode:(SGFFPacket *)packet error:(NSError * __autoreleasing *)error
{
    __block NSArray <id <SGFFFrame>> * result = nil;
    CMSampleBufferRef sampleBuffer = [self sampleBufferFromData:packet.corePacket->data size:packet.corePacket->size];
    if (sampleBuffer != NULL)
    {
        OSStatus status = VTDecompressionSessionDecodeFrameWithOutputHandler(_decompressionSession, sampleBuffer, 0, nil, ^(OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef  _Nullable imageBuffer, CMTime presentationTimeStamp, CMTime presentationDuration) {
            if (status == noErr)
            {
                if (imageBuffer)
                {
                    SGFFVideoFrame * frame = [[SGFFObjectPool sharePool] objectWithClass:[SGFFVideoFrame class]];
                    [frame updateDataType:SGFFVideoFrameDataTypeCVPixelBuffer];
                    [frame updateCorePixelBuffer:imageBuffer];
                    frame.timebase = self.timebase;
                    [frame fillWithPacket:packet.corePacket];
                    result = @[frame];
                }
            }
        });
        if (status == kVTInvalidSessionErr)
        {
            [self doFlushCodec];
            [NSThread sleepForTimeInterval:SGFFTimebaseConvertToSeconds(packet.duration, self.timebase)];
        }
        CFRelease(sampleBuffer);
    }
    return result;
}
    
    
#pragma mark - VideoToolbox

- (BOOL)setupDecompressionSession
{
    if (self.codecpar->codec_id != AV_CODEC_ID_H264)
    {
        return NO;
    }
    uint8_t * extradata = self.codecpar->extradata;
    int extradata_size = self.codecpar->extradata_size;
    if (extradata_size < 7 || extradata == NULL)
    {
        return NO;
    }
    if (extradata[0] == 1)
    {
        if (extradata[4] == 0xFE)
        {
            extradata[4] = 0xFF;
            self.shouldConvertNALSize3To4 = YES;
        }
        _formatDescription = CreateFormatDescription(kCMVideoCodecType_H264,
                                                     self.codecpar->width,
                                                     self.codecpar->height,
                                                     extradata,
                                                     extradata_size);
        if (_formatDescription == NULL)
        {
            return NO;
        }
        NSDictionary * destinationImageBufferAttributes = @{(NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange),
                                                            (NSString *)kCVPixelBufferWidthKey : @(self.codecpar->width),
                                                            (NSString *)kCVPixelBufferHeightKey : @(self.codecpar->height)};
        OSStatus status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                                       _formatDescription,
                                                       NULL,
                                                       (__bridge CFDictionaryRef)destinationImageBufferAttributes,
                                                       NULL,
                                                       &_decompressionSession);
        if (status != noErr)
        {
            _decompressionSession = NULL;
            return NO;
        }
        return YES;
    }
    return NO;
}

- (void)destoryDecompressionSession
{
    if (_decompressionSession)
    {
        VTDecompressionSessionWaitForAsynchronousFrames(_decompressionSession);
        VTDecompressionSessionInvalidate(_decompressionSession);
        CFRelease(_decompressionSession);
        _decompressionSession = NULL;
    }
    if (_formatDescription)
    {
        CFRelease(_formatDescription);
        _formatDescription = NULL;
    }
    self.shouldConvertNALSize3To4 = NO;
}

- (CMSampleBufferRef)sampleBufferFromData:(void *)data size:(size_t)size
{
    CMSampleBufferRef sampleBuffer = NULL;
    if (self.shouldConvertNALSize3To4)
    {
        AVIOContext * io_context = NULL;
        if (avio_open_dyn_buf(&io_context) > 0)
        {
            uint32_t nal_size;
            uint8_t * end = data + size;
            uint8_t * nal_start = data;
            while (nal_start < end)
            {
                nal_size = (nal_start[0] << 16) | (nal_start[1] << 8) | nal_start[2];
                avio_wb32(io_context, nal_size);
                nal_start += 3;
                avio_write(io_context, nal_start, nal_size);
                nal_start += nal_size;
            }
            uint8_t * demux_buffer = NULL;
            int demux_size = avio_close_dyn_buf(io_context, &demux_buffer);
            sampleBuffer = CreateSampleBuffer(_formatDescription, demux_buffer, demux_size);
        }
    }
    else
    {
        sampleBuffer = CreateSampleBuffer(_formatDescription, data, size);
    }
    return sampleBuffer;
}

static CMSampleBufferRef CreateSampleBuffer(CMFormatDescriptionRef formatDescription, void * data, size_t size)
{
    OSStatus status;
    CMBlockBufferRef blockBuffer = NULL;
    CMSampleBufferRef sampleBuffer = NULL;
    status = CMBlockBufferCreateWithMemoryBlock(NULL, data, size, kCFAllocatorNull, NULL, 0, size, FALSE, &blockBuffer);
    if (status == noErr)
    {
        status = CMSampleBufferCreate(NULL, blockBuffer, TRUE, 0, 0, formatDescription, 1, 0, NULL, 0, NULL, &sampleBuffer);
    }
    if (blockBuffer)
    {
        CFRelease(blockBuffer);
    }
    if (status != noErr)
    {
        if (!sampleBuffer)
        {
            CFRelease(sampleBuffer);
        }
        return NULL;
    }
    return sampleBuffer;
}
    
static CMFormatDescriptionRef CreateFormatDescription(CMVideoCodecType codec_type,
                                                      int width,
                                                      int height,
                                                      const uint8_t * extradata,
                                                      int extradata_size)
{
    OSStatus status;
    CMFormatDescriptionRef formatDescription = nil;
    NSDictionary * pixelAspectRatio = @{@"HorizontalSpacing" : @(0),
                                        @"VerticalSpacing" : @(0)};
    NSDictionary * sampleDescriptionExtensionAtoms = @{@"avcC" : [NSData dataWithBytes:extradata length:extradata_size]};
    NSDictionary * extensions = @{@"CVImageBufferChromaLocationBottomField" : @"left",
                                  @"CVImageBufferChromaLocationTopField" : @"left",
                                  @"FullRangeVideo" : @(NO),
                                  @"CVPixelAspectRatio" : pixelAspectRatio,
                                  @"SampleDescriptionExtensionAtoms" : sampleDescriptionExtensionAtoms};
    status = CMVideoFormatDescriptionCreate(NULL,
                                            codec_type,
                                            width,
                                            height,
                                            (__bridge CFDictionaryRef)extensions,
                                            &formatDescription);
    if (status != noErr)
    {
        return NULL;
    }
    return formatDescription;
}

@end
