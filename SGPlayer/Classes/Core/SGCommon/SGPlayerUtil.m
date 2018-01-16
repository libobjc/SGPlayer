//
//  SGPlayerUtil.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGPlayerUtil.h"

@implementation SGPlayerUtil

+ (NSInteger)globalPlayerTag
{
    static NSInteger tag = 1900;
    return tag++;
}

@end
