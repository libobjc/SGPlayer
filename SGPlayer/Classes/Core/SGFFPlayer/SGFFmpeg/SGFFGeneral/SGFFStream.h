//
//  SGFFStream.h
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "avformat.h"

@interface SGFFStream : NSObject

@property (nonatomic, assign) AVStream * stream;

@end
