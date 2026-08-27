precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

// Tanh approximation for smooth cinematic clamping
vec4 tanh_polyline(vec4 x) {
    vec4 val = clamp(x, -20.0, 20.0);
    vec4 ex = exp(val);
    vec4 emx = exp(-val);
    return (ex - emx) / (ex + emx);
}

void main() {
    vec2 u = FlutterFragCoord().xy;
    vec4 o = vec4(0.0);

    // 1. Slow down time for a more "Epic/Heavy" feel (Dune is slow-burn)
    float t = uTime * 0.8; 

    vec3 p_res = vec3(uResolution, 0.0);
    vec3 q = vec3(0.0);
    vec3 p = vec3(0.0);

    // Normalize coordinates
    vec2 uv = (u - p_res.xy / 2.0) / p_res.y;
    uv.y *= -1.0; 

    float d = 0.0;
    float s = 0.0;

    // 2. Raymarching Loop
    // Reduced to 80 iterations for better mobile performance without losing detail
    for(int i = 0; i < 80; i++) {
        p = vec3(uv * d, d + t);
        q = p;

        s = 0.03;
        for (int k = 0; k < 7; k++) {
            // Subtle shift: added a slight sine wobble to simulate heat rising
            p += vec3(abs(dot(sin(p * s * 4.0 + t * 0.1), vec3(0.035))) / s);
            s += s;
        }

        float cosVal = cos(p.x) * 0.2;
        vec3 term1 = vec3(0.2) - q - vec3(cosVal);
        vec3 term2 = vec3(2.5) + p;

        vec3 minVal = min(term1, term2);
        float valY = minVal.y;

        s = 0.04 + 0.6 * abs(valY);
        d += s;

        o += 1.0 / s;
    }

    // 3. Cinematic Color Grading
    // We use a "Sandy Gold" palette: R=4.0, G=1.8, B=0.8
    float len = length(uv - vec2(0.0, 0.2)); // Shifted focus slightly up
    vec4 col = vec4(4.0, 1.8, 0.8, 1.0) * o / 4000.0 / len;
    
    o = tanh_polyline(col);

    // 4. Vertical Vignette / Grounding
    // This darkens the bottom of the screen where "PORTFOLIO MMXXV" sits
    // ensuring the secondary text is always legible.
    float vignette = smoothstep(-0.6, 0.5, uv.y);
    o.rgb *= (vignette * 0.8 + 0.2); 

    fragColor = vec4(o.rgb, 1.0);
}
