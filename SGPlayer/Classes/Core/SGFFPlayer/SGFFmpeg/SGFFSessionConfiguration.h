//
//  SGFFSessionConfiguration.h
//  SGPlayer
//
//  Created by Single on 2018/1/31.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFSource.h"
#import "SGFFCodec.h"
#import "SGFFOutput.h"

@interface SGFFSessionConfiguration : NSObject

@property (nonatomic, assign) BOOL enableVideoToolBox;

@property (nonatomic, strong) id <SGFFOutput> audioOutput;
@property (nonatomic, strong) id <SGFFOutput> videoOutput;

@end
