//
//  SGFFTime.h
//  SGPlayer
//
//  Created by Single on 2018/1/18.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "avformat.h"

AVRational SGFFTimebaseValidate(AVRational timebase, AVRational defaultTimebase);
