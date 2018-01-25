//
//  SGGLSphereModel.m
//  SGPlayer
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGGLSphereModel.h"

static GLushort * dataOfIndexes = nil;
static GLfloat * dataOfVertices = nil;
static GLfloat * dataOfTextureCoordinates = nil;

static int const numberOfSlices = 200;
static int const numberOfParallels = numberOfSlices / 2;

static int const numberOfIndexes = numberOfSlices * numberOfParallels * 6;
static int const numberOfVertices = (numberOfSlices + 1) * (numberOfParallels + 1);

@implementation SGGLSphereModel

+ (void)prepareData
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        float const step = (2.0f * M_PI) / (float)numberOfSlices;
        float const radius = 1.0f;
        
        dataOfIndexes = malloc(sizeof(GLushort) * numberOfIndexes);
        dataOfVertices = malloc(sizeof(GLfloat) * 3 * numberOfVertices);
        dataOfTextureCoordinates = malloc(sizeof(GLfloat) * 2 * numberOfVertices);
        
        int runCount = 0;
        for (int i = 0; i < numberOfParallels + 1; i++)
        {
            for (int j = 0; j < numberOfSlices + 1; j++)
            {
                int vertex = (i * (numberOfSlices + 1) + j) * 3;
                if (dataOfVertices)
                {
                    dataOfVertices[vertex + 0] = radius * sinf(step * (float)i) * cosf(step * (float)j);
                    dataOfVertices[vertex + 1] = radius * cosf(step * (float)i);
                    dataOfVertices[vertex + 2] = radius * sinf(step * (float)i) * sinf(step * (float)j);
                }
                if (dataOfTextureCoordinates)
                {
                    int textureIndex = (i * (numberOfSlices + 1) + j) * 2;
                    dataOfTextureCoordinates[textureIndex + 0] = (float)j / (float)numberOfSlices;
                    dataOfTextureCoordinates[textureIndex + 1] = ((float)i / (float)numberOfParallels);
                }
                if (dataOfIndexes && i < numberOfParallels && j < numberOfSlices)
                {
                    dataOfIndexes[runCount++] = i * (numberOfSlices + 1) + j;
                    dataOfIndexes[runCount++] = (i + 1) * (numberOfSlices + 1) + j;
                    dataOfIndexes[runCount++] = (i + 1) * (numberOfSlices + 1) + (j + 1);
                    
                    dataOfIndexes[runCount++] = i * (numberOfSlices + 1) + j;
                    dataOfIndexes[runCount++] = (i + 1) * (numberOfSlices + 1) + (j + 1);
                    dataOfIndexes[runCount++] = i * (numberOfSlices + 1) + (j + 1);
                }
            }
        }
    });
}

- (GLushort *)dataOfIndexes
{
    [SGGLSphereModel prepareData];
    return dataOfIndexes;
}

- (GLfloat *)dataOfVertices
{
    [SGGLSphereModel prepareData];
    return dataOfVertices;
}
- (GLfloat *)dataOfTextureCoordinates
{
    [SGGLSphereModel prepareData];
    return dataOfTextureCoordinates;
}

- (int)numberOfIndexes
{
    return numberOfIndexes;
}

- (int)numberOfVertices
{
    return numberOfVertices;
}

@end
