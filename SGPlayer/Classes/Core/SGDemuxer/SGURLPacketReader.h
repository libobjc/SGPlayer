//
//  SGURLPacketReader.h
//  SGPlayer iOS
//
//  Created by Single on 2018/9/19.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGPacketReadable.h"

@interface SGURLPacketReader : NSObject <SGPacketReadable>

- (instancetype)initWithURL:(NSURL *)URL;

@end
