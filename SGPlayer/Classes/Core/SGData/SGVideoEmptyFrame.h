//
//  SGVideoEmptyFrame.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGVideoFrame.h"

@interface SGVideoEmptyFrame : SGVideoFrame

- (void)fillWithPacket:(SGPacket *)packet;

@end
