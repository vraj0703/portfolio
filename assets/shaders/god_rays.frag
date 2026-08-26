precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;// Screen Size
uniform vec2 uLightPos;// Light Position
uniform vec2 uLogoPos;// Logo Center
uniform vec2 uLogoSize;// Logo Size
uniform vec2 uCursorPos;
uniform sampler2D uLogoTexture;// Your current logo image

out vec4 fragColor;

// Random Noise Generator (Gold Noise)
float random(vec2 xy) {
return fract(tan(distance(xy * 1.61803398874989484820459, xy) * 1.41421356237309504880169));
}

// Simple texture sampler
float sampleAlpha(vec2 worldPos) {
vec2 localPos = worldPos - (uLogoPos - uLogoSize * 0.5);
vec2 uv = localPos / uLogoSize;

// If outside the logo box, return 0 (No object)
if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
return 0.0;
}

float distance = texture(uLogoTexture, uv).a;

// We use a very small, fixed value for the edge width.
// This avoids the fwidth() crash and produces a sharp result.
//
// HOW TO TUNE THIS:
// - Smaller value = Sharper, more aliased edge.
// - Larger value = Softer, more anti-aliased edge.
// A value of 0.005 is a great starting point for high-res SDFs.
float edgeWidth = 0.5;

// Use smoothstep for a perfect anti-aliased transition.
float alpha = smoothstep(0.5 - edgeWidth, 0.5 + edgeWidth, distance);

return alpha;

}

void main() {
    vec2 pixelPos = FlutterFragCoord().xy;

    // --- COLORS ---
    vec3 floorColor = vec3(0.81, 0.66, 0.41);// Light Grey Base
    vec3 shadowColor = vec3(0.56, 0.3, 0.21);// Darker Shadow

    // Vector from pixel to light
    vec2 toLight = uLightPos - pixelPos;
    float distToLight = length(toLight);
    vec2 rayDir = normalize(toLight);

    // --- RAY MARCHING SETUP ---
    // Lower steps = more performance. Jitter hides the low count.
    const int steps = 120;
    float stepSize = distToLight / float(steps);

    // --- THE SECRET SAUCE: JITTER ---
    // We offset the start position by a random amount (0.0 to 1.0)
    // This turns "Banding Artifacts" into "Cinematic Grain"
    float noise = random(pixelPos);
    float currentDist = noise * stepSize;

    float shadowAccumulation = 0.0;
    // Controls how "foggy" the shadow looks
    float shadowSoftness = 6.0;

    // --- THE LOOP ---
    for (int i = 0; i < steps; i++) {
        vec2 samplePos = pixelPos + rayDir * currentDist;

        float alpha = sampleAlpha(samplePos);

        if (alpha > 0.1) {
            // Distance Weighting:
            // Objects close to pixel (small currentDist) = Sharp Shadow
            // Objects far from pixel (large currentDist) = Soft/No Shadow
            float weight = 1.0 - (currentDist / distToLight);
            weight = pow(weight, 2.0);// Curve the falloff for realism

            shadowAccumulation += alpha * weight * shadowSoftness / float(steps);
        }

        // Move ray forward
        currentDist += stepSize;
    }

    // Clamp shadow intensity
    float t = clamp(shadowAccumulation, 0.0, 1.0);

    // --- FINAL MIX ---
    // 1. Apply the shadow to the floor color
    // We also add a tiny bit of noise to the floor itself for texture
    vec3 noisyFloor = floorColor * (0.98 + 0.04 * noise);

    vec3 finalColor = mix(noisyFloor, shadowColor, t);

    float d = distToLight / uSize.y;

    // 2. The Core (The physical light bulb)
    // 0.015 = roughly 1.5% of screen height
    // We invert smoothstep to make the center solid and edge transparent
    float core = 1.0 - smoothstep(0.0, 0.015, d);

    // 3. The Glow (The Atmosphere)
    // exp() creates that beautiful "Dune" bloom
    float glow = exp(-d * 10.0) * 0.45;

    // 4. Define Colors
    //vec3 sunCoreColor = vec3(1.0, 1.0, 0.9);// White-hot center
    vec3 sunGlowColor = vec3(1.0, 0.75, 0.79);// Golden orange halo

    // 5. Additive Blending (Physics)
    // We add the core and glow on top of the shadowed floor
    finalColor += sunGlowColor * glow;
    fragColor = vec4(finalColor, 1.0);
}

