//
//  SGFFAudioFrame.h
//  SGPlayer
//
//  Created by Single on 2017/2/17.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGFFFrame.h"

@interface SGFFAudioFrame : SGFFFrame

{
@public
    float * samples;
    int length;
    int output_offset;
}

- (void)setSamplesLength:(NSUInteger)samplesLength;

@end
