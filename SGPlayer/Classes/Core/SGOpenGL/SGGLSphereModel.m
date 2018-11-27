//
//  SGGLSphereModel.m
//  SGPlayer
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGGLSphereModel.h"

static GLushort *indexes_data = nil;
static GLfloat *vertices_data = nil;
static GLfloat *textureCoordinates_data = nil;

static int const slices_count = 200;
static int const parallels_count = slices_count / 2;

static int const indexes_count = slices_count * parallels_count * 6;
static int const vertices_count = (slices_count + 1) * (parallels_count + 1);

@implementation SGGLSphereModel

+ (void)prepareData
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        float const step = (2.0f * M_PI) / (float)slices_count;
        float const radius = 1.0f;
        
        indexes_data = malloc(sizeof(GLushort) * indexes_count);
        vertices_data = malloc(sizeof(GLfloat) * 3 * vertices_count);
        textureCoordinates_data = malloc(sizeof(GLfloat) * 2 * vertices_count);
        
        int runCount = 0;
        for (int i = 0; i < parallels_count + 1; i++) {
            for (int j = 0; j < slices_count + 1; j++) {
                int vertex = (i * (slices_count + 1) + j) * 3;
                if (vertices_data) {
                    vertices_data[vertex + 0] = radius * sinf(step * (float)i) * cosf(step * (float)j);
                    vertices_data[vertex + 1] = radius * cosf(step * (float)i);
                    vertices_data[vertex + 2] = radius * sinf(step * (float)i) * sinf(step * (float)j);
                }
                if (textureCoordinates_data) {
                    int textureIndex = (i * (slices_count + 1) + j) * 2;
                    textureCoordinates_data[textureIndex + 0] = (float)j / (float)slices_count;
                    textureCoordinates_data[textureIndex + 1] = ((float)i / (float)parallels_count);
                }
                if (indexes_data && i < parallels_count && j < slices_count) {
                    indexes_data[runCount++] = i * (slices_count + 1) + j;
                    indexes_data[runCount++] = (i + 1) * (slices_count + 1) + j;
                    indexes_data[runCount++] = (i + 1) * (slices_count + 1) + (j + 1);
                    indexes_data[runCount++] = i * (slices_count + 1) + j;
                    indexes_data[runCount++] = (i + 1) * (slices_count + 1) + (j + 1);
                    indexes_data[runCount++] = i * (slices_count + 1) + (j + 1);
                }
            }
        }
    });
}

- (GLushort *)indexes_data
{
    [SGGLSphereModel prepareData];
    return indexes_data;
}

- (GLfloat *)vertices_data
{
    [SGGLSphereModel prepareData];
    return vertices_data;
}
- (GLfloat *)textureCoordinates_data
{
    [SGGLSphereModel prepareData];
    return textureCoordinates_data;
}

- (int)indexes_count
{
    return indexes_count;
}

- (int)vertices_count
{
    return vertices_count;
}

@end
