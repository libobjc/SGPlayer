//
//  SGVideoProcessor.m
//  SGPlayer
//
//  Created by Single on 2019/8/13.
//  Copyright © 2019 single. All rights reserved.
//

#import "SGVideoProcessor.h"

@interface SGVideoProcessor ()

@property (nonatomic, strong, readonly) SGTrackSelection *selection;

@end

@implementation SGVideoProcessor

- (void)setSelection:(SGTrackSelection *)selection action:(SGTrackSelectionAction)action
{
    self->_selection = [selection copy];
}

- (__kindof SGFrame *)putFrame:(__kindof SGFrame *)frame
{
    if (![self->_selection.tracks containsObject:frame.track]) {
        [frame unlock];
        return nil;
    }
    return frame;
}

- (__kindof SGFrame *)finish
{
    return nil;
}

- (SGCapacity)capacity
{
    return SGCapacityCreate();
}

- (void)flush
{

}

- (void)close
{

}

@end
