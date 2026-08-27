#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uScrollProgress;
uniform sampler2D uTexture;
uniform vec2 uTextSize;
uniform float uOpacity;

out vec4 fragColor;

// Reduced from 800 → 200. Each iteration does rand×2 + exp×2 + distance.
// 800 was pure over-engineering for a starfield that blurs via additive
// alpha; 200 stars produce visually identical density after the bloom/
// composite pass and cut per-pixel cost 4×. Matters during contact entrance
// where this shader runs alongside beach.frag (the real GPU hog).
#define NUM_STARS 200

// --- AUTHORIZED PALETTE ---
const vec3 C_LIGHT  = vec3(1.00, 0.88, 0.51);// #FFE082 (Shine/High Speed Stars)
const vec3 C_ORANGE = vec3(0.90, 0.54, 0.30);// #E68A4D (Stars)
const vec3 C_MUTED  = vec3(0.84, 0.65, 0.37);// #D6A65F (Glow Ambient)
const vec3 C_DARK   = vec3(0.60, 0.28, 0.18);// #9A482F (Glow Core)
const vec3 C_MID    = vec3(0.78, 0.55, 0.32);// #C78E53 (Primary Stars)

float rand(float x) { return fract(sin(x) * 123.456); }

float cross2(vec2 a, vec2 b) { return a.x * b.y - a.y * b.x; }

float getDistanceSP(vec2 s, vec2 t, vec2 p) {
    if (dot(t - s, p - s) < 0.0) return distance(p, s);
    if (dot(s - t, p - t) < 0.0) return distance(p, t);
    return abs(cross2(t - s, p - s) / distance(t, s));
}

void main() {
    if (uScrollProgress <= 0.001 || uScrollProgress >= 0.999) {
        fragColor = vec4(0.0);
        return;
    }

    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = (fragCoord - 0.5 * uSize.xy) / uSize.y;
    vec2 globalUv = fragCoord / uSize.xy;

    float dist = length(uv);

    vec3 centerColor = C_LIGHT * 0.6;// Much brighter base (was 0.3)
    vec3 edgeColor = C_DARK * 0.1;// Dark edge
    vec3 bgGradient = mix(centerColor, edgeColor, smoothstep(0.0, 1.2, dist));

    float hotCore = exp(-5.0 * dist);
    bgGradient += C_LIGHT * hotCore * 0.5;// Additive hot spot

    vec3 starCol = bgGradient;
    float starAlpha = 0.2 + hotCore * 0.5;// Core is also opaque

    float t = uScrollProgress * 7.0;
    float td = max(t - 1.5, 0.0);
    float visibility = smoothstep(0.0, 0.1, uScrollProgress) * (1.0 - smoothstep(0.9, 1.0, uScrollProgress));

    for (int i = 0; i < NUM_STARS; i++) {
        float fi = float(i);
        vec2 c = vec2(rand(fi * 1.2) * 2.0 - 1.0, rand(fi * 2.3) * 2.0 - 1.0);
        float r = rand(fi * 4.5) * 0.0004;

        vec2 n = c * (exp(t * 1.2) - 1.0) * 0.001;
        float d = (getDistanceSP(c, c + n, uv) - r);
        float intensity = exp(-1800.0 * d);

        vec3 colChoice = (mod(fi, 2.0) == 0.0) ? C_MID : C_ORANGE;
        if (mod(fi, 10.0) == 0.0) colChoice = C_LIGHT;

        starCol += colChoice * intensity;
        starAlpha += intensity;

        float glowIntensity = (exp(t * 0.00004) - 1.0) + (exp(td * td * 0.006) - 1.0) * (0.015 / length(uv));
        starCol += mix(C_ORANGE, C_LIGHT, uScrollProgress) * glowIntensity * 0.02;// Increased multiplier from 0.005 to 0.02
        starAlpha += glowIntensity * 0.1;// Increased alpha contribution
    }

    float scale = 1.0;
    float blurRadius = 0.0;
    float textOpacity = 1.0;
    float shine = 0.0;

    float snapOvershoot = 2.5;

    if (uScrollProgress < 0.45) {
        float p = uScrollProgress / 0.45;
        float t = p - 1.0;
        float ease = t * t * ((snapOvershoot + 1.0) * t + snapOvershoot) + 1.0;

        scale = mix(0.8, 1.0, ease);
        blurRadius = (1.0 - p) * 0.03;
        textOpacity = p;
    }
    else if (uScrollProgress > 0.6) {
        float p = (uScrollProgress - 0.6) / 0.4;
        scale = mix(1.0, 1.5, p * p);// Zoom In
        blurRadius = p * 0.04;
        textOpacity = 1.0 - p;
    }
    else {
        scale = 1.0;
        blurRadius = 0.0;
        textOpacity = 1.0;
    }

    float shinePos = mix(-0.5, 1.5, uScrollProgress);
    shine = smoothstep(0.2, 0.0, abs(globalUv.x - shinePos));

    vec2 textOrigin = (uSize - uTextSize) * 0.5;
    vec2 tUv = (fragCoord - textOrigin) / uTextSize;

    tUv = (tUv - 0.5) * (1.0 / scale) + 0.5;

    vec4 textSample = vec4(0.0);

    float shadowAlpha = 0.0;
    if (tUv.x >= -0.01 && tUv.x <= 1.01 && tUv.y >= -0.01 && tUv.y <= 1.01) {
        vec2 shadowUV = tUv - vec2(0.006, 0.006);// Bottom-right shadow (visual)
        if (shadowUV.x >= 0.0 && shadowUV.x <= 1.0 && shadowUV.y >= 0.0 && shadowUV.y <= 1.0) {
            shadowAlpha = texture(uTexture, shadowUV).a * 0.6;// 60% opacity shadow
        }
    }

    float blurFade = 1.0 - smoothstep(0.0, 0.01, blurRadius);
    shadowAlpha *= blurFade;

    if (tUv.x >= 0.0 && tUv.x <= 1.0 && tUv.y >= 0.0 && tUv.y <= 1.0) {
        if (blurRadius > 0.001) {
            for (float x = -1.0; x <= 1.0; x += 1.0) {
                for (float y = -1.0; y <= 1.0; y += 1.0) {
                    textSample += texture(uTexture, tUv + vec2(x, y) * blurRadius);
                }
            }
            textSample /= 9.0;
        } else {
            textSample = texture(uTexture, tUv);
        }

        if (textSample.a > 0.01) {
            vec3 cSilverDark  = vec3(0.25, 0.30, 0.35);// Deep Gunmetal (Ground) - Was 0.65
            vec3 cSilverLight = vec3(0.95, 0.98, 1.00);// Platinum
            vec3 cChrome      = vec3(1.00, 1.00, 1.00);
            float reflectionY = tUv.y + uScrollProgress * 0.1;
            float horizon = smoothstep(0.40, 0.60, reflectionY);// Softer horizon

            vec3 metalColor = mix(cSilverDark, cSilverLight, horizon);
            float ridge = 1.0 - abs((reflectionY - 0.5) * 5.0);
            ridge = max(0.0, ridge);
            metalColor += cChrome * pow(ridge, 4.0) * 0.5;// Tighter, sharper glint
            metalColor += sin(tUv.x * 200.0) * 0.02;

            textSample.rgb = metalColor;
            textSample.rgb += shine * C_LIGHT * 1.2;
        }

        textSample.a *= textOpacity;
    }
    vec3 bgWithShadow = mix(starCol * visibility, vec3(0.0), shadowAlpha * textOpacity);
    vec3 finalRGB = mix(bgWithShadow, textSample.rgb, textSample.a);
    float finalA = clamp((starAlpha * visibility) + shadowAlpha + textSample.a, 0.0, 1.0);
    if (uScrollProgress > 0.9) {
        float flash = smoothstep(0.9, 0.95, uScrollProgress) * (1.0 - smoothstep(0.95, 1.0, uScrollProgress));
        finalRGB = mix(finalRGB, C_LIGHT, flash);
        finalA = mix(finalA, 1.0, flash);
    }

    fragColor = vec4(finalRGB, finalA * uOpacity);
}