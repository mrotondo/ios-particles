//
//  Shader.vsh
//  iOSParticles
//
//  Created by Mike Rotondo on 5/14/12.
//  Copyright (c) 2012 Mike Rotondo. All rights reserved.
//

attribute vec4 position;
attribute vec4 color;
attribute vec2 texCoord;

varying vec4 vColor;
varying vec2 vTexCoord;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

void main()
{
    vTexCoord = texCoord;
    vColor = color;
    
    gl_Position = projectionMatrix * position;
}
