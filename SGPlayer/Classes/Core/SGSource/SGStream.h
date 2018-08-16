//
//  SGStream.h
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGDefines.h"
#import "SGTime.h"
#import "avformat.h"

@interface SGStream : NSObject

@property (nonatomic, assign) AVStream * coreStream;

- (SGMediaType)mediaType;
- (int)index;
- (AVRational)timebase;

@end
