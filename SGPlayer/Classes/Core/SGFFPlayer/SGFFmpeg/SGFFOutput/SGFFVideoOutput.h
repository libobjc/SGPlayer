//
//  SGFFVideoOutput.h
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFOutput.h"
#import "SGPLFView.h"

@class SGFFVideoOutput;

@protocol SGFFVideoOutputDelegate <NSObject>

- (void)videoOutputDidChangeDisplayView:(SGFFVideoOutput *)output;

@end

@interface SGFFVideoOutput : NSObject <SGFFOutput>

@property (nonatomic, weak) id <SGFFOutput> referenceOutput;
@property (nonatomic, weak) id <SGFFVideoOutputDelegate> delegate;

- (SGPLFView *)displayView;

@end
