//
//  SGFFVideoToolBox.m
//  SGPlayer
//
//  Created by Single on 2017/2/21.
//  Copyright © 2017年 single. All rights reserved.
//

#import <SGPlatform/SGPlatform.h>
#import "SGFFVideoToolBox.h"

typedef NS_ENUM(NSUInteger, SGFFVideoToolBoxErrorCode) {
    SGFFVideoToolBoxErrorCodeExtradataSize,
    SGFFVideoToolBoxErrorCodeExtradataData,
    SGFFVideoToolBoxErrorCodeCreateFormatDescription,
    SGFFVideoToolBoxErrorCodeCreateSession,
    SGFFVideoToolBoxErrorCodeNotH264,
};

@interface SGFFVideoToolBox ()

{
    AVCodecContext * _codec_context;
    VTDecompressionSessionRef _vt_session;
    CMFormatDescriptionRef _format_description;
    
@public
    OSStatus _decode_status;
    CVImageBufferRef _decode_output;
}

@property (nonatomic, assign) BOOL vtSessionToken;
@property (nonatomic, assign) BOOL needConvertNALSize3To4;

@end

@implementation SGFFVideoToolBox

+ (instancetype)videoToolBoxWithCodecContext:(AVCodecContext *)codecContext
{
    return [[self alloc] initWithCodecContext:codecContext];
}

- (instancetype)initWithCodecContext:(AVCodecContext *)codecContext
{
    if (self = [super init]) {
        self->_codec_context = codecContext;
    }
    return self;
}

- (BOOL)trySetupVTSession
{
    if (!self.vtSessionToken) {
        NSError * error = [self setupVTSession];
        if (!error) {
            self.vtSessionToken = YES;
        }
    }
    return self.vtSessionToken;
}

- (NSError *)setupVTSession
{
    NSError * error;
    
    enum AVCodecID codec_id = self->_codec_context->codec_id;
    uint8_t * extradata = self->_codec_context->extradata;
    int extradata_size = self->_codec_context->extradata_size;
    
    if (codec_id == AV_CODEC_ID_H264) {
        if (extradata_size < 7 || extradata == NULL) {
            error = [NSError errorWithDomain:@"extradata error" code:SGFFVideoToolBoxErrorCodeExtradataSize userInfo:nil];
            return error;
        }

        if (extradata[0] == 1) {
            if (extradata[4] == 0xFE) {
                extradata[4] = 0xFF;
                self.needConvertNALSize3To4 = YES;
            }
            self->_format_description = CreateFormatDescription(kCMVideoCodecType_H264, _codec_context->width, _codec_context->height, extradata, extradata_size);
            if (self->_format_description == NULL) {
                error = [NSError errorWithDomain:@"create format description error" code:SGFFVideoToolBoxErrorCodeCreateFormatDescription userInfo:nil];
                return error;
            }
            
            CFMutableDictionaryRef destinationPixelBufferAttributes = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
            cf_dict_set_int32(destinationPixelBufferAttributes, kCVPixelBufferPixelFormatTypeKey, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange);
            cf_dict_set_int32(destinationPixelBufferAttributes, kCVPixelBufferWidthKey, _codec_context->width);
            cf_dict_set_int32(destinationPixelBufferAttributes, kCVPixelBufferHeightKey, _codec_context->height);

#if SGPLATFORM_TARGET_OS_MAC
//            cf_dict_set_boolean(destinationPixelBufferAttributes, kCVPixelBufferOpenGLCompatibilityKey, YES);
//            cf_dict_set_boolean(destinationPixelBufferAttributes, kCVPixelBufferOpenGLTextureCacheCompatibilityKey, YES);
#elif SGPLATFORM_TARGET_OS_IPHONE
//            cf_dict_set_boolean(destinationPixelBufferAttributes, kCVPixelBufferOpenGLESCompatibilityKey, YES);
//            cf_dict_set_boolean(destinationPixelBufferAttributes, kCVPixelBufferOpenGLESTextureCacheCompatibilityKey, YES);
#endif
            
            VTDecompressionOutputCallbackRecord outputCallbackRecord;
            outputCallbackRecord.decompressionOutputCallback = outputCallback;
            outputCallbackRecord.decompressionOutputRefCon = (__bridge void *)self;
            
            OSStatus status = VTDecompressionSessionCreate(kCFAllocatorDefault, self->_format_description, NULL, destinationPixelBufferAttributes, &outputCallbackRecord, &self->_vt_session);
            if (status != noErr) {
                error = [NSError errorWithDomain:@"create session error" code:SGFFVideoToolBoxErrorCodeCreateSession userInfo:nil];
                return error;
            }
            CFRelease(destinationPixelBufferAttributes);
            return nil;
        } else {
            error = [NSError errorWithDomain:@"deal extradata error" code:SGFFVideoToolBoxErrorCodeExtradataData userInfo:nil];
            return error;
        }
    } else {
        error = [NSError errorWithDomain:@"not h264 error" code:SGFFVideoToolBoxErrorCodeNotH264 userInfo:nil];
        return error;
    }
    
    return error;
}

- (void)cleanVTSession
{
    if (self->_format_description) {
        CFRelease(self->_format_description);
        self->_format_description = NULL;
    }
    if (self->_vt_session) {
        VTDecompressionSessionWaitForAsynchronousFrames(self->_vt_session);
        VTDecompressionSessionInvalidate(self->_vt_session);
        CFRelease(self->_vt_session);
        self->_vt_session = NULL;
    }
    self.needConvertNALSize3To4 = NO;
    self.vtSessionToken = NO;
}

- (void)cleanDecodeInfo
{
    self->_decode_status = noErr;
    self->_decode_output = NULL;
}

- (BOOL)sendPacket:(AVPacket)packet needFlush:(BOOL *)needFlush
{
    BOOL setupResult = [self trySetupVTSession];
    if (!setupResult) return NO;
    [self cleanDecodeInfo];
    
    BOOL result = NO;
    CMBlockBufferRef blockBuffer = NULL;
    OSStatus status = noErr;
    
    if (self.needConvertNALSize3To4) {
        AVIOContext * io_context = NULL;
        if (avio_open_dyn_buf(&io_context) < 0) {
            status = -1900;
        } else {
            uint32_t nal_size;
            uint8_t * end = packet.data + packet.size;
            uint8_t * nal_start = packet.data;
            while (nal_start < end) {
                nal_size = (nal_start[0] << 16) | (nal_start[1] << 8) | nal_start[2];
                avio_wb32(io_context, nal_size);
                nal_start += 3;
                avio_write(io_context, nal_start, nal_size);
                nal_start += nal_size;
            }
            uint8_t * demux_buffer = NULL;
            int demux_size = avio_close_dyn_buf(io_context, &demux_buffer);
            status = CMBlockBufferCreateWithMemoryBlock(NULL, demux_buffer, demux_size, kCFAllocatorNull, NULL, 0, packet.size, FALSE, &blockBuffer);
        }
    } else {
        status = CMBlockBufferCreateWithMemoryBlock(NULL, packet.data, packet.size, kCFAllocatorNull, NULL, 0, packet.size, FALSE, &blockBuffer);
    }
    
    if (status == noErr) {
        CMSampleBufferRef sampleBuffer = NULL;
        status = CMSampleBufferCreate( NULL, blockBuffer, TRUE, 0, 0, self->_format_description, 1, 0, NULL, 0, NULL, &sampleBuffer);
        
        if (status == noErr) {
            status = VTDecompressionSessionDecodeFrame(self->_vt_session, sampleBuffer, 0, NULL, 0);
            if (status == noErr) {
                if (self->_decode_status == noErr && self->_decode_output != NULL) {
                    result = YES;
                }
            } else if (status == kVTInvalidSessionErr) {
                * needFlush = YES;
            }
        }
        if (sampleBuffer) {
            CFRelease(sampleBuffer);
        }
    }
    if (blockBuffer) {
        CFRelease(blockBuffer);
    }
    return result;
}

- (CVImageBufferRef)imageBuffer
{
    if (self->_decode_status == noErr && self->_decode_output != NULL) {
        return self->_decode_output;
    }
    return NULL;
}

- (void)flush
{
    [self cleanVTSession];
    [self cleanDecodeInfo];
}

- (void)dealloc
{
    [self flush];
}

static void outputCallback(void * decompressionOutputRefCon, void * sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef imageBuffer, CMTime presentationTimeStamp, CMTime presentationDuration)
{
    @autoreleasepool
    {
        SGFFVideoToolBox * videoToolBox = (__bridge SGFFVideoToolBox *)decompressionOutputRefCon;
        videoToolBox->_decode_status = status;
        videoToolBox->_decode_output = imageBuffer;
        if (imageBuffer != NULL) {
            CVPixelBufferRetain(imageBuffer);
        }
    }
}

static CMFormatDescriptionRef CreateFormatDescription(CMVideoCodecType codec_type, int width, int height, const uint8_t * extradata, int extradata_size)
{
    CMFormatDescriptionRef format_description = NULL;
    OSStatus status;
    
    CFMutableDictionaryRef par = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFMutableDictionaryRef atoms = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFMutableDictionaryRef extensions = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    
    // CVPixelAspectRatio
    cf_dict_set_int32(par, CFSTR("HorizontalSpacing"), 0);
    cf_dict_set_int32(par, CFSTR("VerticalSpacing"), 0);
    
    // SampleDescriptionExtensionAtoms
    cf_dict_set_data(atoms, CFSTR("avcC"), (uint8_t *)extradata, extradata_size);
    
    // Extensions
    cf_dict_set_string(extensions, CFSTR ("CVImageBufferChromaLocationBottomField"), "left");
    cf_dict_set_string(extensions, CFSTR ("CVImageBufferChromaLocationTopField"), "left");
    cf_dict_set_boolean(extensions, CFSTR("FullRangeVideo"), FALSE);
    cf_dict_set_object(extensions, CFSTR ("CVPixelAspectRatio"), (CFTypeRef *)par);
    cf_dict_set_object(extensions, CFSTR ("SampleDescriptionExtensionAtoms"), (CFTypeRef *)atoms);
    
    status = CMVideoFormatDescriptionCreate(NULL, codec_type, width, height, extensions, &format_description);
    
    CFRelease(extensions);
    CFRelease(atoms);
    CFRelease(par);
    
    if (status != noErr) {
        return NULL;
    }
    return format_description;
}

static void cf_dict_set_data(CFMutableDictionaryRef dict, CFStringRef key, uint8_t * value, uint64_t length)
{
    CFDataRef data;
    data = CFDataCreate(NULL, value, (CFIndex)length);
    CFDictionarySetValue(dict, key, data);
    CFRelease(data);
}

static void cf_dict_set_int32(CFMutableDictionaryRef dict, CFStringRef key, int32_t value)
{
    CFNumberRef number;
    number = CFNumberCreate(NULL, kCFNumberSInt32Type, &value);
    CFDictionarySetValue(dict, key, number);
    CFRelease(number);
}

static void cf_dict_set_string(CFMutableDictionaryRef dict, CFStringRef key, const char * value)
{
    CFStringRef string;
    string = CFStringCreateWithCString(NULL, value, kCFStringEncodingASCII);
    CFDictionarySetValue(dict, key, string);
    CFRelease(string);
}

static void cf_dict_set_boolean(CFMutableDictionaryRef dict, CFStringRef key, BOOL value)
{
    CFDictionarySetValue(dict, key, value ? kCFBooleanTrue: kCFBooleanFalse);
}

static void cf_dict_set_object(CFMutableDictionaryRef dict, CFStringRef key, CFTypeRef *value)
{
    CFDictionarySetValue(dict, key, value);
}

@end
