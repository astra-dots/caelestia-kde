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
    
    // Smooth procedural low-frequency wave drift when time is active
    vec2 animUv = uv;
    if (time > 0.0001) {
        float t = time * 0.75;
        vec2 wave = vec2(
            sin(uv.y * 5.0 + t) * 0.5 + sin(uv.y * 2.2 - t * 0.7) * 0.5,
            cos(uv.x * 5.0 + t * 0.9) * 0.5 + cos(uv.x * 2.2 - t * 0.6) * 0.5
        );
        animUv = clamp(uv + wave * (0.012 * intensity), 0.001, 0.999);
    }
    
    const float GRID_SIZE = 16.0;
    const float CELL_STEP = 1.0 / GRID_SIZE;
    
    vec2 blockUv = floor(animUv * GRID_SIZE) / GRID_SIZE;
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
    
    // Phosphor block luminescence shimmer when animation is active
    if (time > 0.0001) {
        float pulse = 0.035 * sin(blockUv.x * 12.0 + blockUv.y * 12.0 + time * 1.5);
        pixelCol.rgb = clamp(pixelCol.rgb + vec3(pulse * intensity), 0.0, 1.0);
    }
    
    vec4 origCol = texture(source, uv);
    vec4 result = mix(origCol, pixelCol, clamp(intensity, 0.0, 1.0));
    
    fragColor = result * (maskA * qt_Opacity);
}
