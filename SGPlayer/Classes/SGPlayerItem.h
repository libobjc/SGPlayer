//
//  SGPlayerItem.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/10.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface SGPlayerItem : NSObject

- (instancetype)initWithURL:(NSURL *)URL;

@property (nonatomic, strong, readonly) NSURL * URL;
@property (nonatomic, assign) CMTime rate;

@end
