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

// Smooth procedural GLSL 2D Noise functions
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    // Quintic polynomial for C2-continuous smooth interpolation
    f = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// 4-Octave Fractional Brownian Motion with gentle rotation
float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    mat2 rot = mat2(0.866, 0.5, -0.5, 0.866);
    for (int i = 0; i < 4; i++) {
        v += a * noise(p);
        p = rot * p * 1.85 + vec2(0.35, 0.42);
        a *= 0.5;
    }
    return v;
}

// Soft mirror UV helper to prevent edge clamping halos without inverting orientation
vec2 mirrorUV(vec2 p) {
    vec2 t = abs(p);
    vec2 m = 1.0 - abs(mod(t, 2.0) - 1.0);
    return clamp(m, 0.002, 0.998);
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

    // 1. Inigo Quilez Recursive Domain Warping with silky low-frequency flow
    float t = time * 0.12;
    vec2 scaleUv = uv * 1.85;

    vec2 q = vec2(
        fbm(scaleUv + vec2(0.0, 0.0) + t * 0.35),
        fbm(scaleUv + vec2(5.2, 1.3) + t * 0.4)
    );

    vec2 r = vec2(
        fbm(scaleUv + 3.6 * q + vec2(1.7, 9.2) + t * 0.45),
        fbm(scaleUv + 3.6 * q + vec2(8.3, 2.8) + t * 0.4)
    );

    // Silky fluid displacement offset
    vec2 warpOffset = (r - 0.5) * 0.48 * intensity;

    // Tangent flow vector & orthogonal cross-vector
    vec2 flowDir = normalize(r - q + vec2(0.005, 0.005));
    vec2 perpDir = vec2(-flowDir.y, flowDir.x);

    // 2. Vogel Spiral Gaussian Smudge Kernel (Selectable Smoothing)
    const float GOLDEN_ANGLE = 2.39996323;
    vec4 smudgedCol = vec4(0.0);
    float totalWeight = 0.0;

    if (smoothing > 0.5) {
        // Ultra-Smooth 24-Tap Vogel Spiral with Jorge Jimenez IGN Micro-Jitter (zero visible dots)
        const int SAMPLES = 24;
        const float FLOW_RADIUS = 0.092;
        const float CROSS_RADIUS = 0.036;

        float ign = fract(52.9829189 * fract(dot(uv * 800.0, vec2(0.06711056, 0.00583715))));
        float dither = (ign - 0.5) * 0.35;

        for (int i = 0; i < SAMPLES; i++) {
            float fi = float(i);
            float theta = fi * GOLDEN_ANGLE + dither;
            float rRadius = sqrt((fi + 0.5) / float(SAMPLES));

            vec2 offset = flowDir * (cos(theta) * rRadius * FLOW_RADIUS * intensity)
                        + perpDir * (sin(theta) * rRadius * CROSS_RADIUS * intensity);

            vec2 samplePos = mirrorUV(uv + warpOffset + offset);
            float weight = exp(-1.85 * rRadius * rRadius);

            smudgedCol += texture(source, samplePos) * weight;
            totalWeight += weight;
        }
    } else {
        // Classic 16-Tap Vogel Spiral with Spatial Dither
        const int SAMPLES = 16;
        const float FLOW_RADIUS = 0.095;
        const float CROSS_RADIUS = 0.038;

        float dither = hash(uv * 500.0) * 6.2831853;

        for (int i = 0; i < SAMPLES; i++) {
            float fi = float(i);
            float theta = fi * GOLDEN_ANGLE + dither;
            float rRadius = sqrt((fi + 0.5) / float(SAMPLES));

            vec2 offset = flowDir * (cos(theta) * rRadius * FLOW_RADIUS * intensity)
                        + perpDir * (sin(theta) * rRadius * CROSS_RADIUS * intensity);

            vec2 samplePos = mirrorUV(uv + warpOffset + offset);
            float weight = exp(-2.2 * rRadius * rRadius);

            smudgedCol += texture(source, samplePos) * weight;
            totalWeight += weight;
        }
    }

    smudgedCol /= totalWeight;

    // 3. Smooth hover blend back to raw image
    vec3 finalRgb = mix(rawCol.rgb, smudgedCol.rgb, intensity);

    fragColor = vec4(finalRgb, rawCol.a) * maskA * qt_Opacity;
}
