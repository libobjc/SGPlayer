//
//  SGDecodable.h
//  SGPlayer
//
//  Created by Single on 2018/10/22.
//  Copyright © 2018 single. All rights reserved.
//

#ifndef SGDecodable_h
#define SGDecodable_h

#import "SGPacket.h"
#import "SGFrame.h"

@protocol SGDecodable <NSObject>

@property (nonatomic) uint32_t index;

- (NSArray<__kindof SGFrame *> *)decode:(SGPacket *)packet;
- (void)flush;

@end

#endif /* SGDecodable_h */
