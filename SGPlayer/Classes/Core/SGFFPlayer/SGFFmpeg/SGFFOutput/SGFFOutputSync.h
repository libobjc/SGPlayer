//
//  SGFFOutputSync.h
//  SGPlayer
//
//  Created by Single on 2018/1/30.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFOutput.h"

@interface SGFFOutputSync : NSObject

@property (nonatomic, strong) id <SGFFOutput> audioOutput;

@end
