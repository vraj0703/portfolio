precision highp float;

uniform vec2 uSize;
uniform sampler2D uLogoTexture;

out vec4 fragColor;

// This function is identical to the one in your shadow shader
float getAlphaSDF(vec2 uv) {
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        return 0.0;
    }
    float distance = texture(uLogoTexture, uv).a;
    float edgeWidth = 0.5; // Tuned for sharpness
    float alpha = smoothstep(0.5 - edgeWidth, 0.5 + edgeWidth, distance);
    return alpha;
}

void main() {
    // Get the UV coordinates for the current pixel
    vec2 uv = gl_FragCoord.xy / uSize;

    // Calculate the alpha using our sharp SDF logic
    float alpha = getAlphaSDF(uv);

    // Output a solid color (white in this case, we'll tint it in Flutter)
    // The final pixel color is the base color multiplied by the calculated alpha.
    fragColor = vec4(1.0, 1.0, 1.0, 1.0) * alpha;
}