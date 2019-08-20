//
//  SGCodecContext.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/16.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGCodecContext.h"
#import "SGFrame+Internal.h"
#import "SGPacket+Internal.h"
#import "SGOptions.h"
#import "SGObjectPool.h"
#import "SGMapping.h"
#import "SGError.h"
#import "SGMacro.h"

@interface SGCodecContext ()

@property (nonatomic, copy, readonly) Class frameClass;
@property (nonatomic, copy, readonly) NSString *frameReuseName;
@property (nonatomic, assign, readonly) AVRational timebase;
@property (nonatomic, assign, readonly) AVCodecParameters *codecpar;
@property (nonatomic, assign, readonly) AVCodecContext *codecContext;

@end

@implementation SGCodecContext

- (instancetype)initWithTimebase:(AVRational)timebase
                        codecpar:(AVCodecParameters *)codecpar
                      frameClass:(Class)frameClass
                  frameReuseName:(NSString *)frameReuseName
{
    if (self = [super init]) {
        self->_timebase = timebase;
        self->_codecpar = codecpar;
        self->_frameClass = frameClass;
        self->_frameReuseName = frameReuseName;
        self->_options = [SGOptions sharedOptions].decoder.copy;
    }
    return self;
}

- (void)dealloc
{
    [self close];
}

#pragma mark - Interface

- (BOOL)open
{
    if (!self->_codecpar) {
        return NO;
    }
    self->_codecContext = [self createCcodecContext];
    if (!self->_codecContext) {
        return NO;
    }
    return YES;
}

- (void)close
{
    if (self->_codecContext) {
        avcodec_free_context(&self->_codecContext);
        self->_codecContext = nil;
    }
}

- (void)flush
{
    if (self->_codecContext) {
        avcodec_flush_buffers(self->_codecContext);
    }
}

- (NSArray<__kindof SGFrame *> *)decode:(SGPacket *)packet
{
    if (!self->_codecContext) {
        return nil;
    }
    int result = avcodec_send_packet(self->_codecContext, packet ? packet.core : NULL);
    if (result < 0) {
        return nil;
    }
    NSMutableArray *array = [NSMutableArray array];
    while (result != AVERROR(EAGAIN)) {
        __kindof SGFrame *frame = [[SGObjectPool sharedPool] objectWithClass:self->_frameClass reuseName:self->_frameReuseName];
        result = avcodec_receive_frame(self->_codecContext, frame.core);
        if (result < 0) {
            [frame unlock];
            break;
        } else {
            [array addObject:frame];
        }
    }
    return array;
}

#pragma mark - AVCodecContext

- (AVCodecContext *)createCcodecContext
{
    AVCodecContext *codecContext = avcodec_alloc_context3(NULL);
    if (!codecContext) {
        return nil;
    }
    codecContext->opaque = (__bridge void *)self;
    
    int result = avcodec_parameters_to_context(codecContext, self->_codecpar);
    NSError *error = SGGetFFError(result, SGActionCodeCodecSetParametersToContext);
    if (error) {
        avcodec_free_context(&codecContext);
        return nil;
    }
    codecContext->pkt_timebase = self->_timebase;
    if ((self->_options.hardwareDecodeH264 && self->_codecpar->codec_id == AV_CODEC_ID_H264) ||
        (self->_options.hardwareDecodeH265 && self->_codecpar->codec_id == AV_CODEC_ID_H265)) {
        codecContext->get_format = SGCodecContextGetFormat;
    }
    
    AVCodec *codec = avcodec_find_decoder(codecContext->codec_id);
    if (!codec) {
        avcodec_free_context(&codecContext);
        return nil;
    }
    codecContext->codec_id = codec->id;
    
    AVDictionary *opts = SGDictionaryNS2FF(self->_options.options);
    if (self->_options.threadsAuto &&
        !av_dict_get(opts, "threads", NULL, 0)) {
        av_dict_set(&opts, "threads", "auto", 0);
    }
    if (self->_options.refcountedFrames &&
        !av_dict_get(opts, "refcounted_frames", NULL, 0) &&
        (codecContext->codec_type == AVMEDIA_TYPE_VIDEO || codecContext->codec_type == AVMEDIA_TYPE_AUDIO)) {
        av_dict_set(&opts, "refcounted_frames", "1", 0);
    }
    
    result = avcodec_open2(codecContext, codec, &opts);
    
    if (opts) {
        av_dict_free(&opts);
    }
    
    error = SGGetFFError(result, SGActionCodeCodecOpen2);
    if (error) {
        avcodec_free_context(&codecContext);
        return nil;
    }
    
    return codecContext;
}

static enum AVPixelFormat SGCodecContextGetFormat(struct AVCodecContext *s, const enum AVPixelFormat *fmt)
{
    SGCodecContext *self = (__bridge SGCodecContext *)s->opaque;
    for (int i = 0; fmt[i] != AV_PIX_FMT_NONE; i++) {
        if (fmt[i] == AV_PIX_FMT_VIDEOTOOLBOX) {
            AVBufferRef *device_ctx = av_hwdevice_ctx_alloc(AV_HWDEVICE_TYPE_VIDEOTOOLBOX);
            if (!device_ctx) {
                break;
            }
            AVBufferRef *frames_ctx = av_hwframe_ctx_alloc(device_ctx);
            av_buffer_unref(&device_ctx);
            if (!frames_ctx) {
                break;
            }
            AVHWFramesContext *frames_ctx_data = (AVHWFramesContext *)frames_ctx->data;
            frames_ctx_data->format = AV_PIX_FMT_VIDEOTOOLBOX;
            frames_ctx_data->sw_format = SGPixelFormatAV2FF(self->_options.preferredPixelFormat);
            frames_ctx_data->width = s->width;
            frames_ctx_data->height = s->height;
            int err = av_hwframe_ctx_init(frames_ctx);
            if (err < 0) {
                av_buffer_unref(&frames_ctx);
                break;
            }
            s->hw_frames_ctx = frames_ctx;
            return fmt[i];
        }
    }
    return fmt[0];
}

@end
