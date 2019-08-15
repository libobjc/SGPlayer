//
//  SGPlayViewController.h
//  demo-macos
//
//  Created by Single on 2017/3/15.
//  Copyright © 2017年 single. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SGVideoItem.h"

@interface SGPlayViewController : NSViewController

@property (nonatomic, strong) SGVideoItem *videoItem;

- (void)run;

@end
