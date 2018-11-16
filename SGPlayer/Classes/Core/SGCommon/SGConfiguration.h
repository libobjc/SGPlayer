//
//  SGConfiguration.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/29.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGConfiguration : NSObject

+ (instancetype)defaultConfiguration;

@property (nonatomic, copy) NSDictionary * formatContextOptions;
@property (nonatomic, copy) NSDictionary * codecContextOptions;
@property (nonatomic) BOOL threadsAuto;
@property (nonatomic) BOOL refcountedFrames;
@property (nonatomic) BOOL hardwareDecodeH264;
@property (nonatomic) BOOL hardwareDecodeH265;
@property (nonatomic) OSType preferredPixelFormat;

@end
