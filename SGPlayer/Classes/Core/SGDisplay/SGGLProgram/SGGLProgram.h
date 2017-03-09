//
//  SGGLProgram.h
//  SGPlayer
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <SGPlatform/SGPlatform.h>

@interface SGGLProgram : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)programWithVertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader;

@property (nonatomic, assign) GLint program_id;

@property (nonatomic, assign) GLint position_location;
@property (nonatomic, assign) GLint texture_coord_location;
@property (nonatomic, assign) GLint matrix_location;

- (void)use;
- (void)updateMatrix:(GLKMatrix4)matrix;

#pragma mark - subclass override

- (void)setupVariable;
- (void)bindVariable;

@end
