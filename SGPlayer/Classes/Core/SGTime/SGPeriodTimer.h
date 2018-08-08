//
//  SGPeriodTimer.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/8.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGPeriodTimer : NSObject

+ (void)addTarget:(id)target selector:(SEL)selector;
+ (void)removeTarget:(id)target;

@end
