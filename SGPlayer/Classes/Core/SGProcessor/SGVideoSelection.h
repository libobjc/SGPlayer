//
//  SGVideoSelection.h
//  SGPlayer
//
//  Created by Single on 2019/5/30.
//  Copyright © 2019 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGTrack.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *
 */
typedef NS_OPTIONS(NSUInteger, SGVideoSelectionActionFlags) {
    SGVideoSelectionAction_Tracks = 1 << 0,
};

@interface SGVideoSelection : NSObject <NSCopying>

/**
 *
 */
@property (nonatomic, copy) NSArray<SGTrack *> *tracks;

@end

NS_ASSUME_NONNULL_END
