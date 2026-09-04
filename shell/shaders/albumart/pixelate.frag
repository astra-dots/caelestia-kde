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
    float gridSize;
};

layout(binding = 1) uniform sampler2D source;
layout(binding = 2) uniform sampler2D maskSource;

void main() {
    vec2 uv = qt_TexCoord0;
    float maskA = texture(maskSource, uv).a;
    if (maskA <= 0.001) {
        fragColor = vec4(0.0);
        return;
    }
    
    float g = (gridSize >= 4.0) ? floor(gridSize) : 16.0;
    float cellStep = 1.0 / g;
    
    // Rigid, stationary pixel block coordinate - eliminates sub-pixel crawling and aliasing
    vec2 blockUv = floor(uv * g) / g;
    vec2 centerUv = blockUv + vec2(0.5 * cellStep);
    
    vec4 pixelCol;
    
    if (smoothing > 0.5) {
        // Generalized Soft-Kuwahara Filter with Center Feature Anchor
        // Evaluates 5 regions: 4 directional quadrants (TL, TR, BL, BR) + 1 Center Cell Kernel.
        // Uses inverse-variance soft weighting to smooth noisy micro-textures/crowds while
        // fully preserving thin high-contrast features (e.g. rainbow beams, lightning, lines).
        
        vec4 m[5];
        vec3 s[5];
        
        for (int k = 0; k < 5; k++) {
            m[k] = vec4(0.0);
            s[k] = vec3(0.0);
        }
        
        float R = 1.0 * cellStep;
        float S_STEP = R * 0.5;
        
        // Q0: Top-Left (-x, -y)
        for (int i = -2; i <= 0; i++) {
            for (int j = -2; j <= 0; j++) {
                vec2 samplePos = clamp(centerUv + vec2(float(i) * S_STEP, float(j) * S_STEP), 0.001, 0.999);
                vec4 c = texture(source, samplePos);
                m[0] += c;
                s[0] += c.rgb * c.rgb;
            }
        }
        
        // Q1: Top-Right (+x, -y)
        for (int i = 0; i <= 2; i++) {
            for (int j = -2; j <= 0; j++) {
                vec2 samplePos = clamp(centerUv + vec2(float(i) * S_STEP, float(j) * S_STEP), 0.001, 0.999);
                vec4 c = texture(source, samplePos);
                m[1] += c;
                s[1] += c.rgb * c.rgb;
            }
        }
        
        // Q2: Bottom-Left (-x, +y)
        for (int i = -2; i <= 0; i++) {
            for (int j = 0; j <= 2; j++) {
                vec2 samplePos = clamp(centerUv + vec2(float(i) * S_STEP, float(j) * S_STEP), 0.001, 0.999);
                vec4 c = texture(source, samplePos);
                m[2] += c;
                s[2] += c.rgb * c.rgb;
            }
        }
        
        // Q3: Bottom-Right (+x, +y)
        for (int i = 0; i <= 2; i++) {
            for (int j = 0; j <= 2; j++) {
                vec2 samplePos = clamp(centerUv + vec2(float(i) * S_STEP, float(j) * S_STEP), 0.001, 0.999);
                vec4 c = texture(source, samplePos);
                m[3] += c;
                s[3] += c.rgb * c.rgb;
            }
        }
        
        // Q4: Center Anchor (samples within the central cell block [-1, 1])
        for (int i = -1; i <= 1; i++) {
            for (int j = -1; j <= 1; j++) {
                vec2 samplePos = clamp(centerUv + vec2(float(i) * S_STEP * 0.65, float(j) * S_STEP * 0.65), 0.001, 0.999);
                vec4 c = texture(source, samplePos);
                m[4] += c;
                s[4] += c.rgb * c.rgb;
            }
        }
        
        vec4 weightedColor = vec4(0.0);
        float totalW = 0.0;
        
        for (int k = 0; k < 5; k++) {
            m[k] /= 9.0;
            s[k] = abs(s[k] / 9.0 - m[k].rgb * m[k].rgb);
            float variance = s[k].r + s[k].g + s[k].b;
            
            // Soft inverse-variance weighting (preserves center features while smoothing noise)
            float w = 1.0 / pow(1.0 + 35.0 * variance, 3.0);
            
            // Give the center anchor extra priority to maintain thin structural details
            if (k == 4) w *= 1.35;
            
            weightedColor += m[k] * w;
            totalW += w;
        }
        
        pixelCol = weightedColor / max(totalW, 0.0001);
        
        // Vibrancy preservation
        float lum = dot(pixelCol.rgb, vec3(0.2126, 0.7152, 0.0722));
        pixelCol.rgb = mix(vec3(lum), pixelCol.rgb, 1.10);
    } else {
        // Raw crisp point-sampling (unfiltered pixelation)
        pixelCol = texture(source, clamp(centerUv, 0.001, 0.999));
    }
    
    // Dynamic clean holographic shine sweep across pixel cells when animation is enabled
    // Note: NO cell borders / bezels, NO random noise/speckles/glints - only clean diagonal shine sweep
    if (time > 0.0001) {
        float sweepT = fract(time * 0.20);
        float sweepPos = sweepT * 1.8 - 0.4;
        float beamDist = abs((blockUv.x + blockUv.y * 0.35) - sweepPos);
        float coreBeam = smoothstep(0.08, 0.0, beamDist) * 0.32;
        float softBeam = smoothstep(0.18, 0.0, beamDist) * 0.14;
        float shine = coreBeam + softBeam;
        pixelCol.rgb = clamp(pixelCol.rgb + vec3(shine * intensity) * (pixelCol.rgb + vec3(0.35)), 0.0, 1.0);
    }
    
    vec4 origCol = texture(source, uv);
    vec4 result = mix(origCol, pixelCol, clamp(intensity, 0.0, 1.0));
    
    fragColor = result * (maskA * qt_Opacity);
}
