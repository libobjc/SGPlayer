//
//  SGVideoDecoder.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/16.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGDecodable.h"
#import "SGFFDefines.h"

@interface SGVideoDecoder : NSObject <SGDecodable>

@property (nonatomic, strong) NSDictionary * options;
@property (nonatomic, assign) BOOL threadsAuto;
@property (nonatomic, assign) BOOL refcountedFrames;
@property (nonatomic, assign) BOOL hardwareDecodeH264;
@property (nonatomic, assign) BOOL hardwareDecodeH265;
@property (nonatomic, assign) SGAVPixelFormat preferredPixelFormat;

@end
