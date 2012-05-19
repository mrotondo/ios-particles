//
//  ITParticleManager.h
//  iOSParticles
//
//  Created by Mike Rotondo on 5/14/12.
//  Copyright (c) 2012 Mike Rotondo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

// Uniform index.
enum
{
    UNIFORM_MODELVIEW_MATRIX,
    UNIFORM_PROJECTION_MATRIX,
    UNIFORM_COLOR_ARRAY,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_POSITION,
    ATTRIB_TEXCOORD,
    ATTRIB_INSTANCE_INDEX,
    NUM_ATTRIBUTES
};

@protocol IPParticle <NSObject>

@property (nonatomic) GLKVector3 position;
@property (nonatomic) GLKVector3 scales;
@property (nonatomic) GLKVector3 angles;
@property (nonatomic) GLKVector4 color;

@end

@interface IPParticleManager : NSObject

@property (nonatomic) GLuint program;

@property (nonatomic) GLuint texture;

- (void)drawParticles:(NSArray *)particles;

@end
