//
//  SGPointerMap.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/31.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGPointerMap : NSObject

- (void)setObject:(id)object forKey:(id)key;
- (id)objectForKey:(id)key;

- (void)removeObjectForKey:(id)key;
- (void)removeAllObjects;

@end
