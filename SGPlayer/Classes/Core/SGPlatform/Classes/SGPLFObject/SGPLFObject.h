//
//  SGPLFObject.h
//  SGPlatform
//
//  Created by Single on 2017/2/24.
//  Copyright © 2017年 single. All rights reserved.
//

#ifndef SGPLFObject_h
#define SGPLFObject_h

#import "SGPLFTargets.h"

#if SGPLATFORM_TARGET_OS_MAC


#import <Cocoa/Cocoa.h>


#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV


#import <UIKit/UIKit.h>


#endif

#endif /* SGPLFObject_h */
