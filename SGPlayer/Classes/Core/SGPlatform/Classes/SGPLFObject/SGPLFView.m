//
//  SGPLFView.m
//  SGPlatform
//
//  Created by Single on 2017/2/24.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFView.h"
#import "SGPLFScreen.h"

#if SGPLATFORM_TARGET_OS_MAC


void SGPLFViewSetBackgroundColor(SGPLFView * view, SGPLFColor * color)
{
    view.wantsLayer = YES;
    view.layer.backgroundColor = color.CGColor;
}

void SGPLFViewInsertSubview(SGPLFView * superView, SGPLFView * subView, NSInteger index)
{
    if (superView.subviews.count > index) {
        NSView * obj = [superView.subviews objectAtIndex:index];
        [superView addSubview:subView positioned:NSWindowBelow relativeTo:obj];
    } else {
        [superView addSubview:subView];
    }
}

SGPLFImage * SGPLFViewGetCurrentSnapshot(SGPLFView * view)
{
    CGSize size = CGSizeMake(view.bounds.size.width * SGPLFScreenGetScale(), view.bounds.size.height * SGPLFScreenGetScale());
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(nil,
                                                 size.width,
                                                 size.height,
                                                 8,
                                                 size.width * 4,
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    [view.layer renderInContext:context];
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    NSImage * image = [[NSImage alloc] initWithCGImage:imageRef size:size];
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    CGImageRelease(imageRef);
    return image;
}


#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV


void SGPLFViewSetBackgroundColor(SGPLFView * view, SGPLFColor * color)
{
    view.backgroundColor = color;
}

void SGPLFViewInsertSubview(SGPLFView * superView, SGPLFView * subView, NSInteger index)
{
    [superView insertSubview:subView atIndex:index];
}

SGPLFImage * SGPLFViewGetCurrentSnapshot(SGPLFView * view)
{
    return nil;
}


#endif
