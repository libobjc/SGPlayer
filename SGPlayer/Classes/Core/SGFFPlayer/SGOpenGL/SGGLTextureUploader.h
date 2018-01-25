//
//  SGGLTextureUploader.h
//  SGPlayer
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGGLDefines.h"

@interface SGGLTextureUploader : NSObject

- (void)upload:(uint8_t * [3])data size:(SGGLSize)size;

@end
