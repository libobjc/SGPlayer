//
//  SGAudioDecoder.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/16.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGDecodable.h"

@interface SGAudioDecoder : NSObject <SGDecodable>

@property (nonatomic, strong) NSDictionary * options;
@property (nonatomic, assign) BOOL threadsAuto;
@property (nonatomic, assign) BOOL refcountedFrames;

@end
