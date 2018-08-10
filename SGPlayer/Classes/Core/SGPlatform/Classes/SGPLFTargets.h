//
//  SGPLFTargets.h
//  SGPlatform
//
//  Created by Single on 2017/2/23.
//  Copyright © 2017年 single. All rights reserved.
//

#ifndef SGPLFMacro_h
#define SGPLFMacro_h

#import <TargetConditionals.h>

#define SGPLATFORM_TARGET_OS_MAC        TARGET_OS_OSX
#define SGPLATFORM_TARGET_OS_IPHONE     TARGET_OS_IOS
#define SGPLATFORM_TARGET_OS_TV         TARGET_OS_TV

#define SGPLATFORM_TARGET_OS_MAC_OR_IPHONE      (SGPLATFORM_TARGET_OS_MAC || SGPLATFORM_TARGET_OS_IPHONE)
#define SGPLATFORM_TARGET_OS_MAC_OR_TV          (SGPLATFORM_TARGET_OS_MAC || SGPLATFORM_TARGET_OS_TV)
#define SGPLATFORM_TARGET_OS_IPHONE_OR_TV       (SGPLATFORM_TARGET_OS_IPHONE || SGPLATFORM_TARGET_OS_TV)

#endif /* SGPLFMacro_h */
