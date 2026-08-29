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

// Convert RGB to HSV for clean vibrance/saturation boost
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Enhance color distinctiveness and saturation
vec3 boostColor(vec3 col, float hueShift, float satBoost) {
    vec3 hsv = rgb2hsv(col);
    hsv.x = fract(hsv.x + hueShift);
    hsv.y = clamp(hsv.y * satBoost + 0.15, 0.0, 1.0);
    hsv.z = clamp(hsv.z * 1.1 + 0.05, 0.1, 0.95);
    return hsv2rgb(hsv);
}

void main() {
    vec2 uv = qt_TexCoord0;
    float maskA = texture(maskSource, uv).a;
    if (maskA <= 0.001) {
        fragColor = vec4(0.0);
        return;
    }

    vec4 rawCol = texture(source, uv);

    if (intensity <= 0.001) {
        fragColor = rawCol * maskA * qt_Opacity;
        return;
    }

    // 1. Extract 5 spatial color anchors from the album artwork
    const float R = 0.09;
    vec3 c0 = sampleRegion(source, vec2(0.18, 0.18), R).rgb; // Top-Left
    vec3 c1 = sampleRegion(source, vec2(0.82, 0.18), R).rgb; // Top-Right
    vec3 c2 = sampleRegion(source, vec2(0.50, 0.50), R).rgb; // Center
    vec3 c3 = sampleRegion(source, vec2(0.18, 0.82), R).rgb; // Bottom-Left
    vec3 c4 = sampleRegion(source, vec2(0.82, 0.82), R).rgb; // Bottom-Right

    // Enhance and differentiate hues to prevent muddy neutral blends
    c0 = boostColor(c0, 0.00, 1.35);
    c1 = boostColor(c1, 0.08, 1.40);
    c2 = boostColor(c2, -0.05, 1.25);
    c3 = boostColor(c3, -0.10, 1.35);
    c4 = boostColor(c4, 0.06, 1.40);

    // 2. Harmonic orbital movement with distinct wave periods
    float t = time * 0.7;
    vec2 p0 = vec2(0.28 + 0.22 * sin(t * 0.45 + 0.5), 0.22 + 0.20 * cos(t * 0.60 + 1.2));
    vec2 p1 = vec2(0.72 + 0.20 * cos(t * 0.50 + 2.1), 0.28 + 0.22 * sin(t * 0.40 + 0.7));
    vec2 p2 = vec2(0.50 + 0.28 * sin(t * 0.35 + 3.4), 0.50 + 0.25 * cos(t * 0.55 + 2.8));
    vec2 p3 = vec2(0.25 + 0.22 * cos(t * 0.65 + 4.1), 0.75 + 0.20 * sin(t * 0.50 + 3.1));
    vec2 p4 = vec2(0.75 + 0.22 * sin(t * 0.55 + 1.8), 0.78 + 0.22 * cos(t * 0.45 + 4.9));

    // 3. Multi-angle fluid domain-warp coordinate field
    vec2 warpedUV = uv;
    warpedUV.x += 0.12 * sin(uv.y * 3.2 + t * 0.7) + 0.06 * cos(uv.x * 4.8 + t * 0.9);
    warpedUV.y += 0.12 * cos(uv.x * 3.2 + t * 0.7) + 0.06 * sin(uv.y * 4.8 + t * 0.9);

    // 4. Sharp distance power weighting (exponent 3.0) to prevent color muddying
    float d0 = 1.0 / pow(distance(warpedUV, p0) + 0.08, 3.0);
    float d1 = 1.0 / pow(distance(warpedUV, p1) + 0.08, 3.0);
    float d2 = 1.0 / pow(distance(warpedUV, p2) + 0.08, 3.0);
    float d3 = 1.0 / pow(distance(warpedUV, p3) + 0.08, 3.0);
    float d4 = 1.0 / pow(distance(warpedUV, p4) + 0.08, 3.0);

    float totalW = d0 + d1 + d2 + d3 + d4;
    vec3 gradCol = (c0 * d0 + c1 * d1 + c2 * d2 + c3 * d3 + c4 * d4) / totalW;

    // Multi-angle angular harmonic shimmer for rich iridescent lighting
    float angle = atan(warpedUV.y - 0.5, warpedUV.x - 0.5);
    float sweep = 0.5 + 0.5 * sin(angle * 2.0 + t * 0.5);
    gradCol = mix(gradCol, gradCol * (0.9 + 0.2 * sweep), 0.35);

    // 5. Smooth hover transition back to original artwork
    vec3 finalRgb = mix(rawCol.rgb, gradCol, intensity);

    fragColor = vec4(finalRgb, rawCol.a) * maskA * qt_Opacity;
}
