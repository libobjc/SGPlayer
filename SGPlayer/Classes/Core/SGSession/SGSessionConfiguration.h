//
//  SGSessionConfiguration.h
//  SGPlayer
//
//  Created by Single on 2018/1/31.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGSource.h"
#import "SGOutput.h"

@interface SGSessionConfiguration : NSObject

@property (nonatomic, assign) BOOL hardwareDecodeEnableH264;
@property (nonatomic, assign) BOOL hardwareDecodeEnableH265;

@property (nonatomic, strong) id <SGOutput> audioOutput;
@property (nonatomic, strong) id <SGOutput> videoOutput;

@end
