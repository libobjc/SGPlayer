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
@property (nonatomic, assign) BOOL threadsAuto;
@property (nonatomic, assign) BOOL refcountedFrames;
@property (nonatomic, assign) BOOL hardwareDecodeH264;
@property (nonatomic, assign) BOOL hardwareDecodeH265;
@property (nonatomic, assign) OSType preferredPixelFormat;

@end
