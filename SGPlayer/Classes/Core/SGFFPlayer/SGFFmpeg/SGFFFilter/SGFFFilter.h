//
//  SGFFFilter.h
//  SGPlayer
//
//  Created by Single on 2018/1/31.
//  Copyright © 2018年 single. All rights reserved.
//

#ifndef SGFFFilter_h
#define SGFFFilter_h


#import <Foundation/Foundation.h>


@protocol SGFFFilter <NSObject>

- (id <SGFFFrame>)processingFrame:(id <SGFFFrame>)frame;

@end


#endif /* SGFFFilter_h */
