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

// -----------------------------------------------------------------------------
// Simplex 2D Noise for Fluid Domain Warping
// -----------------------------------------------------------------------------
vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 permute(vec3 x) { return mod289(((x * 34.0) + 1.0) * x); }

float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187, 0.366025403784439,
                        -0.577350269189626, 0.024390243902439);
    vec2 i  = floor(v + dot(v, C.yy));
    vec2 x0 = v - i + dot(i, C.xx);
    vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod289(i);
    vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0)) + i.x + vec3(0.0, i1.x, 1.0));
    vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
    m = m * m; m = m * m;
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
    vec3 g;
    g.x = a0.x * x0.x + h.x * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

// -----------------------------------------------------------------------------
// Color Sampling & Enhancement Helpers (Spicy Lyrics vibrant palette extraction)
// -----------------------------------------------------------------------------
vec4 sampleBox(sampler2D tex, vec2 center, float r) {
    vec4 acc = texture(tex, center) * 0.36;
    acc += texture(tex, center + vec2( r,  r)) * 0.16;
    acc += texture(tex, center + vec2(-r,  r)) * 0.16;
    acc += texture(tex, center + vec2( r, -r)) * 0.16;
    acc += texture(tex, center + vec2(-r, -r)) * 0.16;
    return acc;
}

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

// Boost saturation & vibrancy without changing hue (matches Spicy Lyrics filter: saturate(2.5))
vec3 vibrantPaletteColor(vec3 col) {
    vec3 hsv = rgb2hsv(col);
    // Ensure rich color saturation (boost muted album tones into glowing fluid)
    hsv.y = clamp(hsv.y * 1.55 + 0.18, 0.35, 1.0);
    // Keep lightness in rich, luminous range
    hsv.z = clamp(hsv.z * 1.05 + 0.05, 0.25, 0.92);
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

    // -------------------------------------------------------------------------
    // 1. Extract 5 Palette Anchors from Artwork
    // -------------------------------------------------------------------------
    const float R = 0.08;
    vec3 c0 = vibrantPaletteColor(sampleBox(source, vec2(0.22, 0.22), R).rgb); // Top-Left
    vec3 c1 = vibrantPaletteColor(sampleBox(source, vec2(0.78, 0.22), R).rgb); // Top-Right
    vec3 c2 = vibrantPaletteColor(sampleBox(source, vec2(0.50, 0.50), R).rgb); // Center
    vec3 c3 = vibrantPaletteColor(sampleBox(source, vec2(0.22, 0.78), R).rgb); // Bottom-Left
    vec3 c4 = vibrantPaletteColor(sampleBox(source, vec2(0.78, 0.78), R).rgb); // Bottom-Right

    // -------------------------------------------------------------------------
    // 2. Animated Floating Color Emitters (Spicy Lyrics / Apple Music Orbs)
    //    Slow, drifting harmonic orbits that keep the mesh moving organically
    // -------------------------------------------------------------------------
    float t = time * 0.40;

    vec2 p0 = vec2(0.28 + 0.18 * sin(t * 0.65 + 0.0), 0.28 + 0.18 * cos(t * 0.80 + 0.4));
    vec2 p1 = vec2(0.72 + 0.18 * cos(t * 0.70 + 1.3), 0.28 + 0.18 * sin(t * 0.60 + 1.7));
    vec2 p2 = vec2(0.50 + 0.22 * sin(t * 0.55 + 2.5), 0.50 + 0.22 * cos(t * 0.65 + 3.2));
    vec2 p3 = vec2(0.28 + 0.18 * cos(t * 0.75 + 3.9), 0.72 + 0.18 * sin(t * 0.70 + 4.3));
    vec2 p4 = vec2(0.72 + 0.18 * sin(t * 0.60 + 5.1), 0.72 + 0.18 * cos(t * 0.75 + 5.8));

    // -------------------------------------------------------------------------
    // 3. Simplex Fluid Domain Warping
    //    Warps the space between emitters to produce silky liquid plumes & waves
    // -------------------------------------------------------------------------
    float warpFreq = smoothing > 0.5 ? 0.95 : 1.75;
    float warpStrength = (smoothing > 0.5 ? 0.28 : 0.15) * intensity;

    float n1 = snoise(uv * warpFreq + vec2(t * 0.25, -t * 0.20));
    float n2 = snoise(uv * warpFreq + vec2(-t * 0.22, t * 0.28) + vec2(12.0));
    float n3 = snoise(uv * (warpFreq * 2.0) + vec2(t * 0.40, t * 0.35));
    float n4 = snoise(uv * (warpFreq * 2.0) - vec2(t * 0.35, t * 0.40) + vec2(25.0));

    vec2 warp = vec2(n1 * 0.70 + n3 * 0.30, n2 * 0.70 + n4 * 0.30);
    vec2 warpedUV = uv + warp * warpStrength;

    // -------------------------------------------------------------------------
    // 4. Soft Gaussian Metaball Field Blending
    //    - smoothing ON: Deep Kawase ambient wash (sigmaSq = 0.56, ultra-silky, melted)
    //    - smoothing OFF: Focused orbs (sigmaSq = 0.11, distinct color zones & contrast)
    // -------------------------------------------------------------------------
    float sigmaSq = smoothing > 0.5 ? 0.56 : 0.11;

    float w0 = exp(-dot(warpedUV - p0, warpedUV - p0) / sigmaSq);
    float w1 = exp(-dot(warpedUV - p1, warpedUV - p1) / sigmaSq);
    float w2 = exp(-dot(warpedUV - p2, warpedUV - p2) / (sigmaSq * (smoothing > 0.5 ? 1.25 : 1.0)));
    float w3 = exp(-dot(warpedUV - p3, warpedUV - p3) / sigmaSq);
    float w4 = exp(-dot(warpedUV - p4, warpedUV - p4) / sigmaSq);

    float totalW = w0 + w1 + w2 + w3 + w4 + 1e-5;
    vec3 fluidColor = (c0 * w0 + c1 * w1 + c2 * w2 + c3 * w3 + c4 * w4) / totalW;

    // Subtle fluid wave luminosity modulation
    float waveLuma = snoise(warpedUV * (smoothing > 0.5 ? 1.4 : 2.2) + vec2(t * 0.15, t * 0.12)) * (smoothing > 0.5 ? 0.06 : 0.10);
    fluidColor += fluidColor * waveLuma;

    // -------------------------------------------------------------------------
    // 5. Output Styling: Soft Vignette & Saturation Boost
    // -------------------------------------------------------------------------
    vec2 center = uv - 0.5;
    float vignette = 1.0 - dot(center, center) * 0.28;
    fluidColor *= vignette;

    // Extra saturation polish (matching Spicy Lyrics' rich glowing feel)
    float luma = dot(fluidColor, vec3(0.299, 0.587, 0.114));
    fluidColor = mix(vec3(luma), fluidColor, 1.25);

    // Smooth hover crossfade back to original cover art
    vec3 finalRgb = mix(rawCol.rgb, fluidColor, intensity);

    // Sub-LSB Screen-space triangular debanding dither
    float ditherNoise = fract(52.9829189 * fract(dot(gl_FragCoord.xy, vec2(0.06711056, 0.00583715)))) - 0.5;
    finalRgb = clamp(finalRgb + vec3(ditherNoise * (1.2 / 255.0)), 0.0, 1.0);

    fragColor = vec4(finalRgb, rawCol.a) * maskA * qt_Opacity;
}
