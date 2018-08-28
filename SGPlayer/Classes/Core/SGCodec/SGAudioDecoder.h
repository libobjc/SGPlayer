//
//  SGAudioDecoder.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/16.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAsyncDecoder.h"

@interface SGAudioDecoder : SGAsyncDecoder

@property (nonatomic, copy) NSDictionary * options;
@property (nonatomic, assign) BOOL threadsAuto;
@property (nonatomic, assign) BOOL refcountedFrames;

@end
