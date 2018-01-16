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

@class SGFFFrame;

@protocol SGFFFrameDelegate <NSObject>

- (void)frameDidStartPlaying:(SGFFFrame *)frame;
- (void)frameDidStopPlaying:(SGFFFrame *)frame;
- (void)frameDidCancel:(SGFFFrame *)frame;

@end

@interface SGFFFrame : NSObject

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


@interface SGFFSubtileFrame : SGFFFrame

@end


@interface SGFFArtworkFrame : SGFFFrame

@property (nonatomic, strong) NSData * picture;

@end
