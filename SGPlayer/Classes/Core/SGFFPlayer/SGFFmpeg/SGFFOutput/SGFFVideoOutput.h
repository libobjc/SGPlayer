//
//  SGFFVideoOutput.h
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFOutput.h"
#import "SGPlatform.h"

@interface SGFFVideoOutput : NSObject <SGFFOutput>

@property (nonatomic, assign) CMTime rate;

- (SGPLFView *)displayView;

@end
