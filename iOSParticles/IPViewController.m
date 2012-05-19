//
//  ITViewController.m
//  iOSParticles
//
//  Created by Mike Rotondo on 5/14/12.
//  Copyright (c) 2012 Mike Rotondo. All rights reserved.
//

#import "IPViewController.h"
#import "IPParticleManager.h"

@interface IPSimpleParticle : NSObject <IPParticle>
@end
@implementation IPSimpleParticle
@synthesize position, scales, angles, color;
@end

@interface IPViewController ()

@property (strong, nonatomic) EAGLContext *context;

- (void)setupGL;
- (void)tearDownGL;

@end

@implementation IPViewController
{
    GLuint _program;
    
    GLKMatrix4 _projectionMatrix;

    IPParticleManager *_particleManager;
    NSArray *_particles;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self setupGL];

    int numParticles = 50000;
    _particleManager = [[IPParticleManager alloc] init];
    _program = _particleManager.program;
    _particles = [self generateParticles:numParticles];
    
    self.preferredFramesPerSecond = 60;
}

- (void)viewDidUnload
{    
    [super viewDidUnload];
    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
	self.context = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc. that aren't in use.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

#pragma mark - Particles

- (NSArray *)generateParticles:(int)numParticles
{
    NSMutableArray *particles = [NSMutableArray arrayWithCapacity:numParticles];
    for (int i = 0; i < numParticles; i++)
    {
        IPSimpleParticle *particle = [[IPSimpleParticle alloc] init];
        particle.position = GLKVector3Make((arc4random() / (float)0x100000000),
                                           (arc4random() / (float)0x100000000),
                                           0);
        particle.scales = GLKVector3Make(0.01 * (arc4random() / (float)0x100000000),
                                         0.01 * (arc4random() / (float)0x100000000),
                                         0);
        particle.angles = GLKVector3Make(0,
                                         0,
                                         2 * M_PI * (arc4random() / (float)0x100000000));
        particle.color = GLKVector4Make((arc4random() / (float)0x100000000),
                                        (arc4random() / (float)0x100000000),
                                        (arc4random() / (float)0x100000000),
                                        (arc4random() / (float)0x100000000));
        [particles addObject:particle];
    }
    return particles;
}

- (void)updateParticles
{
    for (id<IPParticle> particle in _particles)
    {
        GLKVector3 translation = GLKVector3Make(-0.001 + 0.002 * (arc4random() / (float)0x100000000),
                                                -0.001 + 0.002 * (arc4random() / (float)0x100000000),
                                                0);
        particle.position = GLKVector3Add(particle.position, translation);
    }
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    GLKMatrix4 orthoMatrix;
    float aspect = self.view.bounds.size.width / self.view.bounds.size.height;
    if (aspect <= 1.0)
    {
        orthoMatrix = GLKMatrix4MakeOrtho(0, 1, //0, aspect,
                                          0, 1 / aspect, //0, 1,
                                          -1, 1);
    }
    else
    {
        orthoMatrix = GLKMatrix4MakeOrtho(0, aspect, //0, 1,
                                          0, 1, //0, 1 / aspect,
                                          -1, 1);
    }
    
    _projectionMatrix = orthoMatrix;
    
    [self updateParticles];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    // Render the object again with ES2
    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_PROJECTION_MATRIX], 1, 0, _projectionMatrix.m);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_MATRIX], 1, 0, GLKMatrix4Identity.m);

    glClearColor(0.15f, 0.15f, 0.15f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
    
    [_particleManager drawParticles:_particles];
    
    glDisable(GL_BLEND);
}

@end
