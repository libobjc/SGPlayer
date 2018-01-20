//
//  SGFFLog.h
//  SGPlayer
//
//  Created by Single on 2018/1/20.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>


void SGFFLogCallback(void * context, int level, const char * format, va_list args);


@interface SGFFLog : NSObject

@end
