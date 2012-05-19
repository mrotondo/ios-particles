//
//  ITParticleManager.m
//  iOSParticles
//
//  Created by Mike Rotondo on 5/14/12.
//  Copyright (c) 2012 Mike Rotondo. All rights reserved.
//

#import "IPParticleManager.h"

// Attribute index.
enum
{
    ATTRIB_POSITION,
    ATTRIB_COLOR,
    ATTRIB_TEXCOORD,
    NUM_ATTRIBUTES
};

typedef struct _ParticleVertex {
    GLKVector4 position;
    GLKVector4 color;
    GLKVector2 texCoord;
} ParticleVertex;

@implementation IPParticleManager
{
    int numVerticesPerParticle;
    int numIndicesPerParticle;

    GLKVector4 *quadVertices;
    GLKVector2 *texCoords;
    
    ParticleVertex *vertices;
    unsigned int *indices;
    int maxParticlesPerDrawCall;
    
    GLint textureUniformIndex;
}

- (id)init
{
    self = [super init];
    if (self) {
        numVerticesPerParticle = 4;
        numIndicesPerParticle = 6;
        
        [self loadShaders];
        
        [self generateGeometry];
        
        [self allocateVertexAndIndexArrays];
        
        NSError *error;
        GLKTextureInfo *circleTexture = [GLKTextureLoader textureWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"white_circle" ofType:@"png"] options:@{} error:&error];
        if (!circleTexture)
        {
            NSLog(@"Error loading texture for particle manager! %@", error);
        }
        self.texture = circleTexture.name;

        textureUniformIndex = glGetUniformLocation(self.program, "texture");
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, self.texture);
        glUniform1i(textureUniformIndex, 0);
    }
    return self;
}

- (void)dealloc
{
    free(quadVertices);
    free(texCoords);
    
    free(vertices);
    free(indices);
}

- (void)allocateVertexAndIndexArrays
{
    maxParticlesPerDrawCall = 5000;
    vertices = (ParticleVertex *)malloc(numVerticesPerParticle * maxParticlesPerDrawCall * sizeof(ParticleVertex));
    indices = (unsigned int *)malloc(numIndicesPerParticle * maxParticlesPerDrawCall * sizeof(unsigned int));
}

- (void)generateGeometry
{
    quadVertices = (GLKVector4 *)malloc(numVerticesPerParticle * sizeof(GLKVector4));
    quadVertices[0] = GLKVector4Make(-0.5, -0.5, 0, 1);
    quadVertices[1] = GLKVector4Make(-0.5, 0.5, 0, 1);
    quadVertices[2] = GLKVector4Make(0.5, -0.5, 0, 1);
    quadVertices[3] = GLKVector4Make(0.5, 0.5, 0, 1);

    texCoords = (GLKVector2 *)malloc(numVerticesPerParticle * sizeof(GLKVector2));
    texCoords[0] = GLKVector2Make(0, 0);
    texCoords[1] = GLKVector2Make(0, 1);
    texCoords[2] = GLKVector2Make(1, 0);
    texCoords[3] = GLKVector2Make(1, 1);
}

- (void)drawParticles:(NSArray *)particles
{
    int numParticles = [particles count];
    
    int i = 0;
    for (id<IPParticle> particle in particles)
    {
        GLKVector3 position = particle.position;
        GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(position.x, position.y, 0);
#warning we only rotate around the z axis for now.
        modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, particle.angles.z, 0, 0, 1);
        GLKVector3 scales = particle.scales;
        modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, scales.x, scales.y, scales.z);
        
        for (int j = 0; j < numVerticesPerParticle; j++)
        {
            vertices[i * numVerticesPerParticle + j].position = GLKMatrix4MultiplyVector4(modelViewMatrix, quadVertices[j]);
            vertices[i * numVerticesPerParticle + j].color = particle.color;
            vertices[i * numVerticesPerParticle + j].texCoord = texCoords[j];
        }
        
        indices[i * numIndicesPerParticle + 0] = i * 4 + 0;
        indices[i * numIndicesPerParticle + 1] = i * 4 + 1;
        indices[i * numIndicesPerParticle + 2] = i * 4 + 2;
        indices[i * numIndicesPerParticle + 3] = i * 4 + 3;
        indices[i * numIndicesPerParticle + 4] = i * 4 + 3;
        indices[i * numIndicesPerParticle + 5] = (i + 1) * 4;
        
        ++i;
        
        if (i == maxParticlesPerDrawCall)
        {
            [self drawNumParticles:i];
            i = 0;
        }
    }
    // draw the leftovers
    if (i > 0)
    {
        [self drawNumParticles:i];
    }
}

- (void)drawNumParticles:(unsigned int)numParticles
{
    glEnableVertexAttribArray(ATTRIB_POSITION);
    glEnableVertexAttribArray(ATTRIB_COLOR);
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    glVertexAttribPointer(ATTRIB_POSITION, 4, GL_FLOAT, GL_FALSE, sizeof(ParticleVertex), &vertices[0].position);
    glVertexAttribPointer(ATTRIB_COLOR, 4, GL_FLOAT, GL_FALSE, sizeof(ParticleVertex), &vertices[0].color);
    glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, GL_FALSE, sizeof(ParticleVertex), &vertices[0].texCoord);
    
    glDrawElements(GL_TRIANGLE_STRIP, numParticles * numIndicesPerParticle, GL_UNSIGNED_INT, &indices[0]);
    
    glDisableVertexAttribArray(ATTRIB_POSITION);
    glDisableVertexAttribArray(ATTRIB_COLOR);
    glDisableVertexAttribArray(ATTRIB_TEXCOORD);
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    self.program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, ATTRIB_POSITION, "position");
    glBindAttribLocation(_program, ATTRIB_COLOR, "color");
    glBindAttribLocation(_program, ATTRIB_TEXCOORD, "texCoord");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEW_MATRIX] = glGetUniformLocation(_program, "modelViewMatrix");
    uniforms[UNIFORM_PROJECTION_MATRIX] = glGetUniformLocation(_program, "projectionMatrix");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

@end
