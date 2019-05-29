//
//  SGDecodable.h
//  SGPlayer
//
//  Created by Single on 2018/10/22.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGPacket.h"
#import "SGFrame.h"

NS_ASSUME_NONNULL_BEGIN

@protocol SGDecodable <NSObject>

/**
 *
 */
- (NSArray<__kindof SGFrame *> *)decode:(SGPacket *)packet;

/**
 *
 */
- (NSArray<__kindof SGFrame *> *)finish;

/**
 *
 */
- (void)flush;

@end

NS_ASSUME_NONNULL_END
