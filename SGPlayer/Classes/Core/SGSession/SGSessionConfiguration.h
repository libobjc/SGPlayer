//
//  SGSessionConfiguration.h
//  SGPlayer
//
//  Created by Single on 2018/1/31.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGPacketOutput.h"
#import "SGDecoder.h"
#import "SGOutput.h"

@interface SGSessionConfiguration : NSObject

@property (nonatomic, strong) SGPacketOutput * source;
@property (nonatomic, strong) id <SGDecoder> audioDecoder;
@property (nonatomic, strong) id <SGDecoder> videoDecoder;
@property (nonatomic, strong) id <SGOutput> audioOutput;
@property (nonatomic, strong) id <SGOutput> videoOutput;

@end
