//
//  SGPLFDisplayLink.h
//  SGPlatform
//
//  Created by Single on 2017/2/24.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFObject.h"

#if SGPLATFORM_TARGET_OS_MAC


@interface SGPLFDisplayLink : NSObject

+ (SGPLFDisplayLink *)displayLinkWithTarget:(id)target selector:(SEL)sel;

@property (nonatomic, assign) BOOL paused;

- (void)addToRunLoop:(NSRunLoop *)runloop forMode:(NSRunLoopMode)mode;
- (void)invalidate;

@end


#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV


typedef CADisplayLink SGPLFDisplayLink;


#endif
