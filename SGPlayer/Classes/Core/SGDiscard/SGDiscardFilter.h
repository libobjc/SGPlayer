//
//  SGDiscardFilter.h
//  SGPlayer iOS
//
//  Created by Single on 2018/9/6.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface SGDiscardFilter : NSObject

@property (nonatomic, assign) CMTime minimumInterval;

- (BOOL)discardWithTimeStamp:(CMTime)timeStamp;

- (void)flush;

@end
