//
//  SGFFRendererer.h
//  SGPlayer
//
//  Created by Single on 2018/6/25.
//  Copyright © 2018 single. All rights reserved.
//

#ifndef SGFFRenderer_h
#define SGFFRenderer_h


#import <Foundation/Foundation.h>
#import "SGFFOutputRender.h"


@protocol SGFFRenderer <NSObject>

- (void)prensentRender:(id <SGFFOutputRender>)render;

@end


#endif /* SGFFRenderer_h */
