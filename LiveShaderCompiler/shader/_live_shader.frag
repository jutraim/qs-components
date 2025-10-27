#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
};

/* 
* Here 
* be
* some 
* comments
* :O
*/

vec3 hsv2rgb(vec3 c) {
    vec3 rgb = clamp(abs(mod(c.x * 6.0 + vec3(0.0, 4.0, 2.0),
                             6.0) - 3.0) - 1.0, 0.0, 1.0);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

void main() {
    float h = qt_TexCoord0.x;           // hue
    float s = 1.0 - qt_TexCoord0.y;     // saturation
    float v = 0.2;
    vec3 rgb = hsv2rgb(vec3(h, s, v));
    fragColor = vec4(rgb, qt_Opacity);
} 