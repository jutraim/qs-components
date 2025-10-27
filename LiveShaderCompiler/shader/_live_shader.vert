//common.vert
#version 440

layout(location = 0) in vec4 qt_VertexPosition;
layout(location = 1) in vec2 qt_VertexTexCoord0;

layout(location = 0) out vec2 qt_TexCoord0;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
};

void main() {
    qt_TexCoord0 = qt_VertexTexCoord0;
    gl_Position = qt_Matrix * qt_VertexPosition;
}