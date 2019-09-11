//
//  SGCapacity.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/25.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGTime.h"

typedef struct SGCapacity {
    int size;
    int count;
    CMTime duration;
} SGCapacity;

SGCapacity SGCapacityCreate(void);
SGCapacity SGCapacityAdd(SGCapacity c1, SGCapacity c2);
SGCapacity SGCapacityMinimum(SGCapacity c1, SGCapacity c2);
SGCapacity SGCapacityMaximum(SGCapacity c1, SGCapacity c2);

BOOL SGCapacityIsEqual(SGCapacity c1, SGCapacity c2);
BOOL SGCapacityIsEnough(SGCapacity c1);
BOOL SGCapacityIsEmpty(SGCapacity c1);
