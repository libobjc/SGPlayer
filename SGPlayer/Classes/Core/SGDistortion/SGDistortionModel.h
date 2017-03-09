//
//  SGDistortionModel.h
//  DistortionDemo
//
//  Created by Single on 26/12/2016.
//  Copyright © 2016 single. All rights reserved.
//

#import <GLKit/GLKit.h>

typedef NS_ENUM(NSUInteger, SGDistortionModelType) {
    SGDistortionModelTypeLeft,
    SGDistortionModelTypeRight,
};

@interface SGDistortionModel : NSObject

+ (instancetype)modelWithModelType:(SGDistortionModelType)modelType;

@property (nonatomic, assign, readonly) SGDistortionModelType modelType;

@property (nonatomic, assign) int index_count;
@property (nonatomic, assign) GLint index_buffer_id;
@property (nonatomic, assign) GLint vertex_buffer_id;

@end
