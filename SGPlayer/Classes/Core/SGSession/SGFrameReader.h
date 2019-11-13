//
//  SGFrameReader.h
//  SGPlayer
//
//  Created by Single on 2019/11/12.
//  Copyright © 2019 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGDemuxerOptions.h"
#import "SGDecoderOptions.h"
#import "SGAsset.h"
#import "SGFrame.h"

@protocol SGFrameReaderDelegate;

@interface SGFrameReader : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithAsset:(SGAsset *)asset;

/**
 *
 */
@property (nonatomic, copy) SGDemuxerOptions *demuxerOptions;

/**
 *
 */
@property (nonatomic, copy) SGDecoderOptions *decoderOptions;

/**
 *
 */
@property (nonatomic, weak) id<SGFrameReaderDelegate> delegate;

/**
 *
 */
@property (nonatomic, copy, readonly) NSArray<SGTrack *> *tracks;

/**
 *
 */
@property (nonatomic, copy, readonly) NSArray<SGTrack *> *selectedTracks;

/**
 *
 */
@property (nonatomic, copy, readonly) NSDictionary *metadata;

/**
 *
 */
@property (nonatomic, readonly) CMTime duration;

/**
 *
 */
- (NSError *)open;

/**
 *
 */
- (NSError *)close;

/**
 *
 */
- (NSError *)seekable;

/**
 *
 */
- (NSError *)seekToTime:(CMTime)time;

/**
 *
 */
- (NSError *)seekToTime:(CMTime)time toleranceBefor:(CMTime)toleranceBefor toleranceAfter:(CMTime)toleranceAfter;

/**
 *
 */
- (NSError *)selectTracks:(NSArray<SGTrack *> *)tracks;

/**
 *
 */
- (NSError *)nextFrame:(__kindof SGFrame **)frame;

@end

@protocol SGFrameReaderDelegate <NSObject>

/**
 *
 */
- (BOOL)frameReaderShouldAbortBlockingFunctions:(SGFrameReader *)frameReader;

@end
