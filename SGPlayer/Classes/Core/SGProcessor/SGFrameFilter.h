//
//  SGFrameFilter.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/30.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFrame.h"

@interface SGFrameFilter : NSObject

- (__kindof SGFrame *)convert:(__kindof SGFrame *)frame;
- (void)flush;
- (void)destroy;

@end
