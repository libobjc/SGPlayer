//
//  SGFFOutputRender.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#ifndef SGFFOutputRender_h
#define SGFFOutputRender_h


#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, SGFFOutputRenderType)
{
    SGFFOutputRenderTypeUnkonwn,
    SGFFOutputRenderTypeVideo,
    SGFFOutputRenderTypeAudio,
    SGFFOutputRenderTypeSubtitle,
};


@protocol SGFFOutputRender <NSObject>

- (SGFFOutputRenderType)type;

- (long long)position;
- (long long)duration;
- (long long)size;

@end


#endif /* SGFFOutputRender_h */
