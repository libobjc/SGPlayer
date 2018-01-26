//
//  SGFFMetadata.h
//  SGPlayer
//
//  Created by Single on 2017/3/6.
//  Copyright © 2017年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFTools.h"

@interface SGFFMetadata : NSObject

+ (instancetype)metadataWithAVDictionary:(AVDictionary *)avDictionary;

@property (nonatomic, strong) NSDictionary * metadata;

@property (nonatomic, copy) NSString * language;
@property (nonatomic, assign) long long BPS;
@property (nonatomic, copy) NSString * duration;
@property (nonatomic, assign) long long number_of_bytes;
@property (nonatomic, assign) long long number_of_frames;

@end
