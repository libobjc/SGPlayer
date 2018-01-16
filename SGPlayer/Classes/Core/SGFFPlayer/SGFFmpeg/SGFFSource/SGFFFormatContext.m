//
//  SGFFFormatContext.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFFormatContext.h"
#import "SGFFUtil.h"
#import "avformat.h"

static int formatContextInterruptCallback(void * ctx)
{
    SGFFFormatContext * obj = (__bridge SGFFFormatContext *)ctx;
    return [obj.delegate sourceShouldExit:obj];
}

@interface SGFFFormatContext ()

{
    AVFormatContext * _formatContext;
}

@property (nonatomic, copy) NSURL * contentURL;
@property (nonatomic, weak) id <SGFFSourceDelegate> delegate;

@property (nonatomic, copy) NSError * error;
@property (nonatomic, strong) NSArray <SGFFCodecInfo *> * codecInfos;

@end

@implementation SGFFFormatContext

- (instancetype)initWithContentURL:(NSURL *)contentURL delegate:(id <SGFFSourceDelegate>)delegate
{
    if (self = [super init])
    {
        self.contentURL = contentURL;
        self.delegate = delegate;
    }
    return self;
}

- (void)prepare
{
    _formatContext = avformat_alloc_context();
    
    if (!_formatContext)
    {
        self.error = SGFFCreateErrorCode(SGFFErrorCodeFormatCreate);
        return;
    }
    
    _formatContext->interrupt_callback.callback = formatContextInterruptCallback;
    _formatContext->interrupt_callback.opaque = (__bridge void *)self;
    
    self.error = [NSError errorWithDomain:@"Single Error" code:0 userInfo:nil];
}

@end
