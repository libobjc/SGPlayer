//
//  SGFFFrame.h
//  SGPlayer
//
//  Created by Single on 06/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SGFFFrameType) {
    SGFFFrameTypeVideo,
    SGFFFrameTypeAVYUVVideo,
    SGFFFrameTypeCVYUVVideo,
    SGFFFrameTypeAudio,
    SGFFFrameTypeSubtitle,
    SGFFFrameTypeArtwork,
};

@class SGFFFrame2;

@protocol SGFFFrameDelegate <NSObject>

- (void)frameDidStartPlaying:(SGFFFrame2 *)frame;
- (void)frameDidStopPlaying:(SGFFFrame2 *)frame;
- (void)frameDidCancel:(SGFFFrame2 *)frame;

@end

@interface SGFFFrame2 : NSObject

@property (nonatomic, weak) id <SGFFFrameDelegate> delegate;
@property (nonatomic, assign, readonly) BOOL playing;

@property (nonatomic, assign) SGFFFrameType type;
@property (nonatomic, assign) NSTimeInterval position;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign, readonly) int size;
@property (nonatomic, assign) int packetSize;

- (void)startPlaying;
- (void)stopPlaying;
- (void)cancel;

@end


@interface SGFFSubtileFrame : SGFFFrame2

@end


@interface SGFFArtworkFrame : SGFFFrame2

@property (nonatomic, strong) NSData * picture;

@end
