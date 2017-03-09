//
//  SGFFAudioFrame.m
//  SGPlayer
//
//  Created by Single on 2017/2/17.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGFFAudioFrame.h"

@implementation SGFFAudioFrame

{
    size_t buffer_size;
}

- (SGFFFrameType)type
{
    return SGFFFrameTypeAudio;
}

- (int)size
{
    return (int)self->length;
}

- (void)setSamplesLength:(NSUInteger)samplesLength
{
    if (self->buffer_size < samplesLength) {
        if (self->buffer_size > 0 && self->samples != NULL) {
            free(self->samples);
        }
        self->buffer_size = samplesLength;
        self->samples = malloc(self->buffer_size);
    }
    self->length = (int)samplesLength;
    self->output_offset = 0;
}

- (void)dealloc
{
    if (self->buffer_size > 0 && self->samples != NULL) {
        free(self->samples);
    }
}

@end
