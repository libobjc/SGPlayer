//
//  SGVideoFrame.m
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGVideoFrame.h"
#import "SGTime.h"

@interface SGVideoFrame ()

@end

@implementation SGVideoFrame

- (SGMediaType)mediaType
{
    return SGMediaTypeVideo;
}

- (instancetype)init
{
    if (self = [super init])
    {
        NSLog(@"%s", __func__);
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
}

- (void)clear
{
    [super clear];
    self.format = AV_PIX_FMT_NONE;
    self.pictureType = AV_PICTURE_TYPE_NONE;
    self.colorRange = AVCOL_RANGE_UNSPECIFIED;
    self.colorPrimaries = AVCOL_PRI_RESERVED0;
    self.colorTransferCharacteristic = AVCOL_TRC_RESERVED0;
    self.colorSpace = AVCOL_SPC_RGB;
    self.chromaLocation = AVCHROMA_LOC_UNSPECIFIED;
    self.width = 0;
    self.height = 0;
    self.keyFrame = 0;
    self.bestEffortTimestamp = 0;
    self.packetPosition = 0;
    self.packetDuration = 0;
    self.packetSize = 0;
    self.data = NULL;
    self.linesize = NULL;
}

@end
