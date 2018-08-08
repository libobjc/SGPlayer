//
//  SGSessionConfiguration.h
//  SGPlayer
//
//  Created by Single on 2018/1/31.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGSource.h"
#import "SGDecoder.h"
#import "SGOutput.h"

@interface SGSessionConfiguration : NSObject

@property (nonatomic, assign) BOOL hardwareDecodeEnableH264;    // Default is YES.
@property (nonatomic, assign) BOOL hardwareDecodeEnableH265;    // Default is YES.

@property (nonatomic, strong) id <SGSource> source;             // nullable
@property (nonatomic, strong) id <SGDecoder> audioDecoder;      // nullable
@property (nonatomic, strong) id <SGDecoder> videoDecoder;      // nullable
@property (nonatomic, strong) id <SGOutput> audioOutput;        // nonnull
@property (nonatomic, strong) id <SGOutput> videoOutput;        // nonnull

@end
