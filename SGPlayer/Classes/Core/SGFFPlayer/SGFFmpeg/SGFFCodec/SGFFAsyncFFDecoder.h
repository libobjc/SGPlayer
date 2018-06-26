//
//  SGFFAsyncFFDecoder.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFAsyncDecoder.h"
#import "SGFFFrame.h"

@interface SGFFAsyncFFDecoder : SGFFAsyncDecoder

- (__kindof id <SGFFFrame>)fetchReuseFrame;

@end
