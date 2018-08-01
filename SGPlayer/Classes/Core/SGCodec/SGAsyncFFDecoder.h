//
//  SGAsyncFFDecoder.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGAsyncDecoder.h"
#import "SGFrame.h"

@interface SGAsyncFFDecoder : SGAsyncDecoder

- (SGFrame *)nextReuseFrame;

@end
