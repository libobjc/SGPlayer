//
//  SGFFPlayerView.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFPlayerView.h"

@implementation SGFFPlayerView

- (void)setView:(SGPLFView *)view
{
    _view = view;
    _view.frame = self.bounds;
    [self addSubview:_view];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.view.frame = self.bounds;
}

@end
