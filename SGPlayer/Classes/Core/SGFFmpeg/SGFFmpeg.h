//
//  SGFFmpeg.h
//  SGPlayer
//
//  Created by Single on 2018/8/2.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "avformat.h"

void SGFFmpegSetupIfNeeded(void);

AVDictionary * SGDictionaryNS2FF(NSDictionary * dictionary);
NSDictionary * SGDictionaryFF2NS(AVDictionary * dictionary);
