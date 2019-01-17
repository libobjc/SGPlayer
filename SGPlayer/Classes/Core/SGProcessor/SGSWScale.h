//
//  SGSWScale.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/28.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGVideoDescription.h"

NS_ASSUME_NONNULL_BEGIN

@interface SGSWScale : NSObject

@property (nonatomic, copy) SGVideoDescription *inputDescription;
@property (nonatomic, copy) SGVideoDescription *outputDescription;

@property (nonatomic) int flags;          // SWS_FAST_BILINEAR

/**
 *
 */
- (BOOL)open;

/**
 *
 */
- (int)convert:(const uint8_t * _Nonnull const [_Nonnull])inputData inputLinesize:(const int [_Nonnull])inputLinesize outputData:(uint8_t * _Nonnull const [_Nonnull])outputData outputLinesize:(const int [_Nonnull])outputLinesize;

@end

NS_ASSUME_NONNULL_END
