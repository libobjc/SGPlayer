//
//  SGURLPreview.h
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGTrack.h"

@protocol SGURLPreviewDelegate;

@interface SGURLPreview : NSObject

- (instancetype)initWithURL:(NSURL *)URL;

@property (nonatomic, weak) id <SGURLPreviewDelegate> delegate;
@property (nonatomic, copy) NSDictionary * options;

- (CMTime)duration;
- (NSError *)seekable;
- (NSDictionary *)metadata;
- (NSArray <SGTrack *> *)tracks;
- (NSArray <SGTrack *> *)audioTracks;
- (NSArray <SGTrack *> *)videoTracks;
- (NSArray <SGTrack *> *)otherTracks;

- (NSError *)open;
- (NSError *)close;

@end

@protocol SGURLPreviewDelegate <NSObject>

- (BOOL)URLPreviewShouldAbortBlockingFunctions:(SGURLPreview *)URLPreview;

@end
