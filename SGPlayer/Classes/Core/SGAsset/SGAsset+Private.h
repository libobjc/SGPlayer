//
//  SGAsset+Private.h
//  SGPlayer iOS
//
//  Created by Single on 2018/9/25.
//  Copyright © 2018 single. All rights reserved.
//

#import <SGPlayer/SGPlayer.h>
#import "SGPacketReadable.h"

@interface SGAsset (Private)

- (id <SGPacketReadable>)newReadable;

@end
