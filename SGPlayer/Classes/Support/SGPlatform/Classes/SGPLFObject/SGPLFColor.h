//
//  SGPLFColor.h
//  SGPlatform
//
//  Created by Single on 2017/2/24.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFObject.h"

#if SGPLATFORM_TARGET_OS_MAC


typedef NSColor SGPLFColor;


#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV


typedef UIColor SGPLFColor;


#endif
