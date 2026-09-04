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

void main() {
    vec2 uv = qt_TexCoord0;
    float maskA = texture(maskSource, uv).a;
    if (maskA <= 0.001) {
        fragColor = vec4(0.0);
        return;
    }
    
    const float GRID_SIZE = 16.0;
    const float CELL_STEP = 1.0 / GRID_SIZE;
    
    // Rigid, stationary pixel block coordinate - eliminates sub-pixel crawling and aliasing
    vec2 blockUv = floor(uv * GRID_SIZE) / GRID_SIZE;
    vec2 centerUv = blockUv + vec2(0.5 * CELL_STEP);
    
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
        
        const float R = 1.0 * CELL_STEP;
        const float S_STEP = R * 0.5;
        
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
    
    // Dynamic sliding retro overlays when animation is enabled
    if (time > 0.0001) {
        float rowId = floor(blockUv.y * GRID_SIZE);

        // 1. Horizontal Sliding Stream Wave (travels sideways across columns)
        float slideX = (blockUv.x * GRID_SIZE) - time * 2.5 + sin(rowId * 0.75) * 1.5;
        float wave = 0.5 + 0.5 * sin(slideX * 0.55);
        float wavePulse = pow(wave, 3.5) * 0.18;

        // 2. Holographic Diagonal Luster Beam (sweeps left to right across pixel cells)
        float sweepT = fract(time * 0.22);
        float sweepPos = sweepT * 1.7 - 0.35;
        float beamDist = abs((blockUv.x + blockUv.y * 0.35) - sweepPos);
        float shine = smoothstep(0.11, 0.0, beamDist) * 0.35;

        // 3. Discrete Chiptune Glints (pixel cells drifting sideways)
        vec2 driftCell = floor(vec2(blockUv.x * GRID_SIZE - time * 1.8, rowId));
        float cellHash = fract(sin(dot(driftCell, vec2(127.1, 311.7))) * 43758.5453);
        float glint = 0.0;
        if (cellHash > 0.88) {
            float phase = time * 4.5 + cellHash * 6.28;
            glint = pow(max(0.0, sin(phase)), 6.0) * 0.30;
        }

        // 4. Subtle Tactile CRT Phosphor Well (crisp block separation, no sub-pixel blur)
        vec2 cellLocal = fract(uv * GRID_SIZE);
        float edgeDist = min(min(cellLocal.x, 1.0 - cellLocal.x), min(cellLocal.y, 1.0 - cellLocal.y));
        float cellBezel = smoothstep(0.0, 0.07, edgeDist) * 0.08 + 0.92;

        // Composite the sliding overlays with color dodge / luminance boost
        vec3 overlayLight = (vec3(wavePulse) + vec3(shine) + vec3(glint)) * intensity;
        pixelCol.rgb = pixelCol.rgb + overlayLight * (pixelCol.rgb + vec3(0.45));
        pixelCol.rgb = clamp(pixelCol.rgb * cellBezel, 0.0, 1.0);
    }
    
    vec4 origCol = texture(source, uv);
    vec4 result = mix(origCol, pixelCol, clamp(intensity, 0.0, 1.0));
    
    fragColor = result * (maskA * qt_Opacity);
}
