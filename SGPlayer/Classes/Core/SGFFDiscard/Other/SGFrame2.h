//
//  SGFrame.h
//  SGPlayer
//
//  Created by Single on 06/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SGFrameType2) {
    SGFrameType2Video,
    SGFrameTypeAVYUVVideo,
    SGFrameTypeCVYUVVideo,
    SGFrameType2Audio,
    SGFrameType2Subtitle,
    SGFrameTypeArtwork,
};

@class SGFrame2;

@protocol SGFrameDelegate <NSObject>

- (void)frameDidStartPlaying:(SGFrame2 *)frame;
- (void)frameDidStopPlaying:(SGFrame2 *)frame;
- (void)frameDidCancel:(SGFrame2 *)frame;

@end

@interface SGFrame2 : NSObject

@property (nonatomic, weak) id <SGFrameDelegate> delegate;
@property (nonatomic, assign, readonly) BOOL playing;

@property (nonatomic, assign) SGFrameType2 type;
@property (nonatomic, assign) NSTimeInterval position;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign, readonly) int size;
@property (nonatomic, assign) int packetSize;

- (void)startPlaying;
- (void)stopPlaying;
- (void)cancel;

@end


@interface SGFFSubtileFrame : SGFrame2

@end


@interface SGFFArtworkFrame : SGFrame2

@property (nonatomic, strong) NSData * picture;

@end
