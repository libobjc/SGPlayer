//
//  SGFFSource.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#ifndef SGFFSource_h
#define SGFFSource_h


#import <Foundation/Foundation.h>
#import "SGFFCodecInfo.h"


@protocol SGFFSource;
@protocol SGFFSourceDelegate;


@protocol SGFFSource <NSObject>

- (instancetype)initWithContentURL:(NSURL *)contentURL delegate:(id <SGFFSourceDelegate>)delegate;
- (NSURL *)contentURL;
- (id <SGFFSourceDelegate>)delegate;
- (NSError *)error;
- (NSArray <SGFFCodecInfo *> *)codecInfos;
- (void)prepare;

@end


@protocol SGFFSourceDelegate <NSObject>

- (BOOL)sourceShouldExit:(id <SGFFSource>)source;

@end


#endif /* SGFFSource_h */
