//
//  SGFFFrame.h
//  SGPlayer
//
//  Created by Single on 2018/1/18.
//  Copyright © 2018年 single. All rights reserved.
//

#ifndef SGFFFrame_h
#define SGFFFrame_h


#import <Foundation/Foundation.h>


@protocol SGFFFrame <NSObject>

- (long long)duration;
- (long long)size;

@end


#endif /* SGFFFrame_h */
