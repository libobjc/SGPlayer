//
//  SGGLTextureUploader.h
//  SGPlayer
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGPLFGLContext.h"
#import "SGVideoFrame.h"

@interface SGGLTextureUploader : NSObject

- (instancetype)initWithGLContext:(SGPLFGLContext *)context;

- (BOOL)uploadWithVideoFrame:(SGVideoFrame *)frame;

@end
