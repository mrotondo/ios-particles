//
//  Shader.vsh
//  iOSParticles
//
//  Created by Mike Rotondo on 5/14/12.
//  Copyright (c) 2012 Mike Rotondo. All rights reserved.
//

attribute vec4 position;
attribute vec2 texCoord;
attribute float instanceIndex;

varying vec2 vTexCoord;
varying float vInstanceIndex;

uniform mat4 modelViewMatrix[255];
uniform mat4 projectionMatrix;

void main()
{
    vTexCoord = texCoord;
    // CRY: We add 0.1 to account for precision errors during interpolation so we can floor it back down in the fragment shader.
    vInstanceIndex = instanceIndex + 0.1;
    
    // CRY: we couldn't use an int vertex attribute for some reason, so we're using a float and casting it :(:(:(
    gl_Position = projectionMatrix * modelViewMatrix[int(floor(instanceIndex + 0.1))] * position;
}
