//
//  SGPlayerItem+Internal.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/25.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGPlayerItem.h"
#import "SGRenderable.h"

@protocol SGPlayerItemInternalDelegate <SGPlayerItemDelegate>

- (void)sessionDidChangeCapacity:(SGPlayerItem *)session;

@end

@interface SGPlayerItem (Internal)

@property (nonatomic, weak) id <SGPlayerItemInternalDelegate> delegateInternal;

@property (nonatomic, strong) id <SGRenderable> audioRenderable;
@property (nonatomic, strong) id <SGRenderable> videoRenderable;

- (NSArray <SGCapacity *> *)capacityWithStreams:(NSArray <SGStream *> *)streams renderables:(NSArray <id <SGRenderable>> *)renderables;

- (BOOL)load;

@end
