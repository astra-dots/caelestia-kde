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

// Procedural GLSL 2D Noise functions
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f); // Hermite cubic smoothstep

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// 4-Octave Fractional Brownian Motion
float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    mat2 rot = mat2(0.8, 0.6, -0.6, 0.8);
    for (int i = 0; i < 4; i++) {
        v += a * noise(p);
        p = rot * p * 2.02 + vec2(0.35, 0.42);
        a *= 0.5;
    }
    return v;
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

    // 1. Inigo Quilez Recursive Domain Warping with evolving time drift
    float t = time * 0.15;
    vec2 scaleUv = uv * 2.8;

    vec2 q = vec2(
        fbm(scaleUv + vec2(0.0, 0.0) + t * 0.4),
        fbm(scaleUv + vec2(5.2, 1.3) + t * 0.5)
    );

    vec2 r = vec2(
        fbm(scaleUv + 4.0 * q + vec2(1.7, 9.2) + t * 0.6),
        fbm(scaleUv + 4.0 * q + vec2(8.3, 2.8) + t * 0.5)
    );

    // Dynamic turbulent displacement
    vec2 warpOffset = (r - 0.5) * 0.55 * intensity;

    // Tangent flow direction for directional acrylic smudge
    vec2 flowDir = normalize(r - q + vec2(0.005, 0.005));

    // 2. Anisotropic 9-Tap Directional Smudge Filter along the liquid flow line
    vec4 smudgedCol = vec4(0.0);
    float totalWeight = 0.0;
    const float SMUDGE_STEP = 0.022;

    for (int k = -4; k <= 4; k++) {
        float weight = 1.0 - abs(float(k)) * 0.18;
        vec2 samplePos = clamp(uv + warpOffset + flowDir * (float(k) * SMUDGE_STEP * intensity), 0.001, 0.999);
        smudgedCol += texture(source, samplePos) * weight;
        totalWeight += weight;
    }
    smudgedCol /= totalWeight;

    // 3. Subtle micro-grain for oil painting texture feel
    float grain = (hash(uv * 100.0 + time * 0.1) - 0.5) * 0.025 * intensity;
    vec3 resultRgb = clamp(smudgedCol.rgb + grain, 0.0, 1.0);

    // 4. Smooth hover blend back to raw image
    vec3 finalRgb = mix(rawCol.rgb, resultRgb, intensity);

    fragColor = vec4(finalRgb, rawCol.a) * maskA * qt_Opacity;
}
