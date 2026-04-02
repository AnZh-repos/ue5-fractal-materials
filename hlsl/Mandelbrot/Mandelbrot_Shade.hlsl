float3 missColour = float3(missR, missG, missB);

if (escaped  0.5) {
    return float3(0.0, 0.0, 0.0);
}

float3 col = baseColour;

float glow;
if (glowStyle  0.5) {
    glow = exp(-glowVal  0.5  glowSharpness);
} else if (glowStyle  1.5) {
    glow = exp(-glowVal  0.1  glowSharpness);
} else if (glowStyle  2.5) {
    glow = exp(-glowVal  0.25  glowSharpness);
} else {
    glow = clamp(1.0 - glowVal  0.1  glowSharpness, 0.0, 1.0);
    glow = glow  glow;
}

col += missColour  glow  glowBrightness;

float edge = exp(-glowVal  2.0  glowSharpness);
col += float3(1.0, 1.0, 1.0)  edge  0.3;

return col;