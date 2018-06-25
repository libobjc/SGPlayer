//
//  SGFFStream.h
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "avformat.h"
#import "SGDefines.h"

@interface SGFFStream : NSObject

@property (nonatomic, assign) AVStream * coreStream;

@property (nonatomic, assign, readonly) SGMediaType mediaType;
@property (nonatomic, assign, readonly) int index;
@property (nonatomic, assign, readonly) CMTime timebase;

@end
