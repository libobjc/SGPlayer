//
//  SGDefines.h
//  SGPlayer
//
//  Created by Single on 2018/6/25.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

#define Noncallback
#define Callbackable

typedef NS_ENUM(int, SGMediaType) {
    SGMediaTypeUnknown,
    SGMediaTypeAudio,
    SGMediaTypeVideo,
    SGMediaTypeSubtitle,
};

typedef void (^SGBlock)(void);
typedef void (^SGSeekResult)(CMTime time, NSError *error);
typedef BOOL (^SGTimeReader)(CMTime *desire, BOOL *drop);
