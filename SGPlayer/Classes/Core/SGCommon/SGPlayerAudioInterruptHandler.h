//
//  SGPlayerAudioInterruptHandler.h
//  SGPlayer
//
//  Created by Single on 2018/1/15.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGPlayerDefinesPrivate.h"

@interface SGPlayerAudioInterruptHandler : NSObject

+ (instancetype)audioInterruptHandlerWithPlayer:(id <SGPlayer, SGPlayerPrivate>)player;

@end
