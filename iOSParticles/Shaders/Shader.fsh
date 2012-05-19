//
//  Shader.fsh
//  iOSParticles
//
//  Created by Mike Rotondo on 5/14/12.
//  Copyright (c) 2012 Mike Rotondo. All rights reserved.
//

uniform sampler2D texture;
uniform lowp vec4 colors[255];

varying mediump vec2 vTexCoord;
varying highp float vInstanceIndex;

void main()
{
    gl_FragColor = colors[int(floor(vInstanceIndex))] * texture2D(texture, vTexCoord);
}
