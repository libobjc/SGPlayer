//
//  SGFFVideoOutput.h
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFOutputInternal.h"
#import "SGPLFView.h"

@class SGFFVideoOutput;

@protocol SGFFVideoOutputDelegate <NSObject>

- (void)videoOutputDidChangeDisplayView:(SGFFVideoOutput *)output;

@end

@interface SGFFVideoOutput : SGFFOutputInternal

@property (nonatomic, weak) id <SGFFVideoOutputDelegate> delegate;
@property (nonatomic, weak) id <SGFFOutput> referenceOutput;

- (SGPLFView *)displayView;

@end
