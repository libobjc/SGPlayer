//
//  SGFFFFFrame.h
//  SGPlayer
//
//  Created by Single on 2018/6/26.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFFFrame.h"
#import "avformat.h"

@interface SGFFFFFrame : SGFFFrame

@property (nonatomic, assign, readonly) AVFrame * coreFrame;

@end
