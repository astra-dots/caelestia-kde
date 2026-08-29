#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float intensity;
    float itemWidth;
    float itemHeight;
    float time;
    float smoothing;
};

layout(binding = 1) uniform sampler2D source;
layout(binding = 2) uniform sampler2D maskSource;

// Multi-tap sample helper to extract local dominant color swatch
vec4 sampleRegion(sampler2D tex, vec2 center, float radius) {
    vec4 acc = vec4(0.0);
    acc += texture(tex, center);
    acc += texture(tex, center + vec2(radius, radius));
    acc += texture(tex, center + vec2(-radius, radius));
    acc += texture(tex, center + vec2(radius, -radius));
    acc += texture(tex, center + vec2(-radius, -radius));
    return acc * 0.2;
}

void main() {
    vec2 uv = qt_TexCoord0;
    float maskA = texture(maskSource, uv).a;
    if (maskA <= 0.001) {
        fragColor = vec4(0.0);
        return;
    }

    vec4 rawCol = texture(source, uv);

    // If effect is disabled or fully hovered away, render raw image
    if (intensity <= 0.001) {
        fragColor = rawCol * maskA * qt_Opacity;
        return;
    }

    // 1. Extract 5 dominant spatial color anchors from the album artwork
    const float R = 0.08;
    vec4 c0 = sampleRegion(source, vec2(0.20, 0.20), R); // Top-Left
    vec4 c1 = sampleRegion(source, vec2(0.80, 0.20), R); // Top-Right
    vec4 c2 = sampleRegion(source, vec2(0.50, 0.50), R); // Center
    vec4 c3 = sampleRegion(source, vec2(0.20, 0.80), R); // Bottom-Left
    vec4 c4 = sampleRegion(source, vec2(0.80, 0.80), R); // Bottom-Right

    // 2. Harmonic orbital movement for the 5 color emitters
    float t = time * 0.65;
    vec2 p0 = vec2(0.30 + 0.22 * sin(t * 0.45 + 0.5), 0.25 + 0.20 * cos(t * 0.60 + 1.2));
    vec2 p1 = vec2(0.70 + 0.20 * cos(t * 0.50 + 2.1), 0.30 + 0.22 * sin(t * 0.40 + 0.7));
    vec2 p2 = vec2(0.50 + 0.25 * sin(t * 0.35 + 3.4), 0.50 + 0.22 * cos(t * 0.55 + 2.8));
    vec2 p3 = vec2(0.28 + 0.20 * cos(t * 0.65 + 4.1), 0.72 + 0.20 * sin(t * 0.50 + 3.1));
    vec2 p4 = vec2(0.75 + 0.22 * sin(t * 0.55 + 1.8), 0.75 + 0.20 * cos(t * 0.45 + 4.9));

    // 3. Fluid domain-warp coordinate field
    vec2 warpedUV = uv;
    warpedUV.x += 0.09 * sin(uv.y * 3.5 + t * 0.7) + 0.05 * cos(uv.x * 5.0 + t * 0.9);
    warpedUV.y += 0.09 * cos(uv.x * 3.5 + t * 0.7) + 0.05 * sin(uv.y * 5.0 + t * 0.9);

    // 4. Soft exponential inverse-distance weighting
    float d0 = 1.0 / (pow(distance(warpedUV, p0), 1.7) + 0.08);
    float d1 = 1.0 / (pow(distance(warpedUV, p1), 1.7) + 0.08);
    float d2 = 1.0 / (pow(distance(warpedUV, p2), 1.7) + 0.08);
    float d3 = 1.0 / (pow(distance(warpedUV, p3), 1.7) + 0.08);
    float d4 = 1.0 / (pow(distance(warpedUV, p4), 1.7) + 0.08);

    float totalW = d0 + d1 + d2 + d3 + d4;
    vec3 gradCol = (c0.rgb * d0 + c1.rgb * d1 + c2.rgb * d2 + c3.rgb * d3 + c4.rgb * d4) / totalW;

    // Subtle gentle contrast & saturation vibrance boost
    vec3 lum = vec3(0.2126, 0.7152, 0.0722);
    float l = dot(gradCol, lum);
    gradCol = mix(vec3(l), gradCol, 1.15); // +15% saturation

    // 5. Smooth hover transition back to original artwork
    vec3 finalRgb = mix(rawCol.rgb, gradCol, intensity);

    fragColor = vec4(finalRgb, rawCol.a) * maskA * qt_Opacity;
}
