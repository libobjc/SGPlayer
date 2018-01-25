//
//  SGGLInternalModel.h
//  SGPlayer
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGGLModel.h"

@interface SGGLInternalModel : NSObject <SGGLModel>

- (GLushort *)dataOfIndexes;
- (GLfloat *)dataOfVertices;
- (GLfloat *)dataOfTextureCoordinates;

- (int)numberOfIndexes;
- (int)numberOfVertices;

@end
