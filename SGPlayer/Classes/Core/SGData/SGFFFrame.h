//
//  SGFFFrame.h
//  SGPlayer
//
//  Created by Single on 2018/8/16.
//  Copyright © 2018 single. All rights reserved.
//

#ifndef SGFFFrame_h
#define SGFFFrame_h

#import <Foundation/Foundation.h>
#import "SGPacket.h"

@protocol SGFFFrame <NSObject>

@property (nonatomic, assign, readonly) AVFrame * coreFrame;

- (void)fillWithPacket:(SGPacket *)packet;

@end

#endif /* SGFFFrame_h */
