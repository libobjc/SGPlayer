//
//  SGGLProgramPool.m
//  SGPlayer
//
//  Created by Single on 2018/1/26.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGGLProgramPool.h"
#import "SGGLYUV420PProgram.h"
#import "SGGLNV12Program.h"
#import "SGGLBGRAProgram.h"

@interface SGGLProgramPool ()

@property (nonatomic, strong) SGGLYUV420PProgram * yuv420p;
@property (nonatomic, strong) SGGLNV12Program * nv12;
@property (nonatomic, strong) SGGLBGRAProgram * bgra;

@end

@implementation SGGLProgramPool

- (id<SGGLProgram>)programWithType:(SGGLProgramType)type
{
    switch (type) {
        case SGGLProgramTypeUnknown:
            return nil;
        case SGGLProgramTypeYUV420P:
            return self.yuv420p;
        case SGGLProgramTypeNV12:
            return self.nv12;
        case SGGLProgramTypeBGRA:
            return self.bgra;
    }
    return nil;
}

- (SGGLYUV420PProgram *)yuv420p
{
    if (!_yuv420p) {
        _yuv420p = [[SGGLYUV420PProgram alloc] init];
    }
    return _yuv420p;
}

- (SGGLNV12Program *)nv12
{
    if (!_nv12)  {
        _nv12 = [[SGGLNV12Program alloc] init];
    }
    return _nv12;
}

- (SGGLBGRAProgram *)bgra
{
    if (!_bgra) {
        _bgra = [[SGGLBGRAProgram alloc] init];
    }
    return _bgra;
}

@end
