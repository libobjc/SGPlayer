//
//  SGMutableAsset.h
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAsset.h"
#import "SGDefines.h"
#import "SGMutableTrack.h"

NS_ASSUME_NONNULL_BEGIN

@interface SGMutableAsset : SGAsset

/**
 *
 */
@property (nonatomic, copy, readonly) NSArray<SGMutableTrack *> *tracks;

/**
 *
 */
- (SGMutableTrack *)addTrack:(SGMediaType)type;

@end

NS_ASSUME_NONNULL_END
