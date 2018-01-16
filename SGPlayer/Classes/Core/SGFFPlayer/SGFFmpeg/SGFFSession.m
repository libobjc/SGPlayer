//
//  SGFFSession.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFSession.h"
#import "SGFFFormatContext.h"
#import "SGFFCodecManager.h"

@interface SGFFSession () <SGFFSourceDelegate>

@property (nonatomic, copy) NSURL * contentURL;
@property (nonatomic, weak) id <SGFFSessionDelegate> delegate;

@property (nonatomic, strong) id <SGFFSource> source;
@property (nonatomic, strong) SGFFCodecManager * codecManager;

@property (nonatomic, strong) NSOperationQueue * operationQueue;
@property (nonatomic, strong) NSInvocationOperation * openSourceOperation;
@property (nonatomic, strong) NSInvocationOperation * readSourceOperation;

@end

@implementation SGFFSession

- (instancetype)initWithContentURL:(NSURL *)contentURL delegate:(id <SGFFSessionDelegate>)delegate
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
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.maxConcurrentOperationCount = 2;
    self.operationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    
    [self openSource];
}

- (void)openSource
{
    self.openSourceOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(openSourceThread) object:nil];
    self.openSourceOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    self.openSourceOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    [self.operationQueue addOperation:self.openSourceOperation];
}

- (void)openSourceThread
{
    self.source = [[SGFFFormatContext alloc] initWithContentURL:self.contentURL delegate:self];
    [self.source prepare];
    self.error = self.source.error;
    
    if (self.error)
    {
        [self callbackForError];
        return;
    }
    
    self.codecManager = [[SGFFCodecManager alloc] init];
    [self.codecManager addCodecs:self.source.codecInfos];
    [self.codecManager prepare];
    self.error = self.codecManager.error;
    
    if (self.error)
    {
        [self callbackForError];
        return;
    }
    
    [self readSource];
}

- (void)readSource
{
    if (self.error)
    {
        [self callbackForError];
        return;
    }
    
    if (!self.readSourceOperation || self.readSourceOperation.isFinished)
    {
        self.readSourceOperation = [[NSInvocationOperation alloc] initWithTarget:self
                                                                        selector:@selector(readSourceThread)
                                                                          object:nil];
        self.readSourceOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
        self.readSourceOperation.qualityOfService = NSQualityOfServiceUserInteractive;
        [self.readSourceOperation addDependency:self.openSourceOperation];
        [self.operationQueue addOperation:self.readSourceOperation];
    }
}

- (void)readSourceThread
{
    
}


#pragma mark - Callback

- (void)callbackForError
{
    if ([self.delegate respondsToSelector:@selector(session:didFailed:)]) {
        [self.delegate session:self didFailed:self.error];
    }
}

@end
