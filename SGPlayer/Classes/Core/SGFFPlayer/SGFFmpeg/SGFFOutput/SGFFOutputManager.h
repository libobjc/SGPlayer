//
//  SGFFOutputManager.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFOutput.h"

@interface SGFFOutputManager : NSObject

@property (nonatomic, strong) id <SGFFOutput> audioOutput;
@property (nonatomic, strong) id <SGFFOutput> videoOutput;

- (id <SGFFOutputRender>)renderWithFrame:(id <SGFFFrame>)frame;

@end
