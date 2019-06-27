//
//  SGMetalModel.h
//  MetalTest
//
//  Created by Single on 2019/6/24.
//  Copyright © 2019 Single. All rights reserved.
//

#import <Metal/Metal.h>

@interface SGMetalModel : NSObject

- (instancetype)initWithDevice:(id<MTLDevice>)device;

@property (nonatomic) NSUInteger indexCount;
@property (nonatomic) MTLIndexType indexType;
@property (nonatomic) MTLPrimitiveType primitiveType;
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLBuffer> indexBuffer;
@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;

@end
