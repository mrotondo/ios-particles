//
//  ITParticleManager.m
//  iOSParticles
//
//  Created by Mike Rotondo on 5/14/12.
//  Copyright (c) 2012 Mike Rotondo. All rights reserved.
//

#import "IPParticleManager.h"

typedef struct _ParticleVertex {
    GLKVector3 position;
    GLKVector2 texCoord;
    float instanceIndex;  // :(:(:( We can't use int vertex attributes so we are passing a float and casting it in the shaders
} ParticleVertex;

@implementation IPParticleManager
{
    int numParticlesPerDrawCall;
    int numVerticesPerParticle;
    int numIndicesPerParticle;
    GLuint vertexBuffer;
    GLuint indexBuffer;
    GLuint vertexArray;

    GLint textureUniformIndex;
}

- (id)init
{
    self = [super init];
    if (self) {
        numParticlesPerDrawCall = 255;
        
        [self loadShaders];
        
        [self generateGeometry];
        
        [self generateVertexArray];
        
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

- (void)generateVertexArray
{
    glGenVertexArraysOES(1, &vertexArray);
    glBindVertexArrayOES(vertexArray);
    
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    
    glEnableVertexAttribArray(ATTRIB_POSITION);
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    glEnableVertexAttribArray(ATTRIB_INSTANCE_INDEX);
    glVertexAttribPointer(ATTRIB_POSITION, 3, GL_FLOAT, GL_FALSE, sizeof(ParticleVertex), (void *)offsetof(ParticleVertex, position));
    glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, GL_FALSE, sizeof(ParticleVertex), (void *)offsetof(ParticleVertex, texCoord));
    glVertexAttribPointer(ATTRIB_INSTANCE_INDEX, 1, GL_FLOAT, GL_FALSE, sizeof(ParticleVertex), (void *)offsetof(ParticleVertex, instanceIndex));
    
    glBindVertexArrayOES(0);
}

- (void)generateGeometry
{
    [self generateVertexBuffer];
    [self generateIndexBuffer];
}

- (void)generateIndexBuffer
{
    numIndicesPerParticle = 6;
    int numIndices = numParticlesPerDrawCall * numIndicesPerParticle;
    unsigned int indices[numIndices];
    
    for (int i = 0; i < numParticlesPerDrawCall; i++)
    {
        indices[i * 6 + 0] = i * 4 + 0;
        indices[i * 6 + 1] = i * 4 + 1;
        indices[i * 6 + 2] = i * 4 + 2;
        indices[i * 6 + 3] = i * 4 + 3;
        indices[i * 6 + 4] = i * 4 + 3;
        indices[i * 6 + 5] = (i + 1) * 4 + 0;
    }
    
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, numIndices * sizeof(unsigned int), indices, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}

- (void)generateVertexBuffer
{
    numVerticesPerParticle = 4;
    int numVertices = numParticlesPerDrawCall * numVerticesPerParticle;
    ParticleVertex vertices[numVertices];
    
    for (int i = 0; i < numParticlesPerDrawCall; i++)
    {
        vertices[i * 4 + 0].position = GLKVector3Make(-0.5, -0.5, 0);
        vertices[i * 4 + 0].texCoord = GLKVector2Make(0, 0);
        vertices[i * 4 + 0].instanceIndex = i;
        
        vertices[i * 4 + 1].position = GLKVector3Make(-0.5, 0.5, 0);
        vertices[i * 4 + 1].texCoord = GLKVector2Make(0, 1);
        vertices[i * 4 + 1].instanceIndex = i;
        
        vertices[i * 4 + 2].position = GLKVector3Make(0.5, -0.5, 0);
        vertices[i * 4 + 2].texCoord = GLKVector2Make(1, 0);
        vertices[i * 4 + 2].instanceIndex = i;
        
        vertices[i * 4 + 3].position = GLKVector3Make(0.5, 0.5, 0);
        vertices[i * 4 + 3].texCoord = GLKVector2Make(1, 1);
        vertices[i * 4 + 3].instanceIndex = i;
    }
    
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, numVertices * sizeof(ParticleVertex), vertices, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

- (void)drawParticles:(NSArray *)particles
{
    glBindVertexArrayOES(vertexArray);

    GLKMatrix4 modelViewMatrices[numParticlesPerDrawCall];
    GLKVector4 colors[numParticlesPerDrawCall];
    
    int i = 0;
    for (id<IPParticle> particle in particles)
    {
        GLKVector3 position = particle.position;
        GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(position.x, position.y, 0);
        modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, particle.angles.z, 0, 0, 1);
        GLKVector3 scales = particle.scales;
        modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, scales.x, scales.y, scales.z);
        modelViewMatrices[i] = modelViewMatrix;
        
        colors[i] = particle.color;
        
        ++i;
    
        if (i == numParticlesPerDrawCall)
        {
            [self drawNumParticles:i withModelViewMatrices:modelViewMatrices andColors:colors];
            i = 0;
        }
    }
    if (i > 0)
    {
        // Draw the leftovers
        [self drawNumParticles:i withModelViewMatrices:modelViewMatrices andColors:colors];
    }

    glBindVertexArrayOES(0);
}

- (void)drawNumParticles:(int)numParticles withModelViewMatrices:(GLKMatrix4 *)modelViewMatrices andColors:(GLKVector4 *)colors
{
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_MATRIX], numParticles, 0, (const GLfloat *)modelViewMatrices);
    glUniform4fv(uniforms[UNIFORM_COLOR_ARRAY], numParticles, (const GLfloat *)colors);
    
    glDrawElements(GL_TRIANGLE_STRIP, numParticles * numIndicesPerParticle, GL_UNSIGNED_INT, (void *)0);
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
    glBindAttribLocation(_program, ATTRIB_TEXCOORD, "texCoord");
    glBindAttribLocation(_program, ATTRIB_INSTANCE_INDEX, "instanceIndex");
    
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
    uniforms[UNIFORM_COLOR_ARRAY] = glGetUniformLocation(_program, "colors");
    
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
