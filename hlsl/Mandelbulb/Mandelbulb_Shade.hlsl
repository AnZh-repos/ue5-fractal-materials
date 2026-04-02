struct MandelbulbFunctions {

    float DE(float3 p, float pw, float pa, out float trap, float trapMethod) {
        float3 z = p;
        float dr = 1.0;
        float r  = 0.0;
        trap = 1000.0;

        for (int i = 0; i < 128; i++) {
            r = length(z);

            if (trapMethod < 0.5) {
                trap = min(trap, length(z.xy));
            } else if (trapMethod < 1.5) {
                trap = min(trap, length(z.xz));
            } else if (trapMethod < 2.5) {
                trap = min(trap, abs(z.x));
            } else if (trapMethod < 3.5) {
                trap = min(trap, length(z));
            } else {
                trap = min(trap, length(z - float3(0.5, 0.3, 0.2)));
            }

            if (r < 0.0001 || r > 2.0) break;

            float theta = acos(clamp(z.z / r, -1.0, 1.0)) + pa;
            float phi   = atan2(z.y, z.x);
            dr          = pow(r, pw - 1.0) * pw * dr + 1.0;
            float zr    = pow(r, pw);
            z = zr * float3(
                sin(theta*pw) * cos(phi*pw),
                sin(theta*pw) * sin(phi*pw),
                cos(theta*pw)
            );
            z += p;
        }
        return 0.5 * log(max(r, 1.0)) * r / dr;
    }
};
MandelbulbFunctions mb;

// matches march node exactly
float pa = sin(time * animSpeed) * 3.14159265;

float3 n = float3(nx, ny, nz);

float3 rayStep = normalize(-viewDir);
float3 viewDir3 = normalize(viewDir);

if (hit > 0.5) {
    float3 lightDir = normalize(float3(lightX, lightY, lightZ));
    float  diffuse  = max(dot(n, lightDir), 0.0);
    float  fill     = max(dot(n, normalize(float3(-0.5, 0.3, 0.2))), 0.0) * 0.25;

    float3 halfVec = normalize(lightDir + viewDir3);
    float  spec    = pow(max(dot(n, halfVec), 0.0), 64.0);

    float ao;
    if (aoMethod < 0.5) {
        ao = pow(clamp(1.0 - stepsTaken / 256.0, 0.0, 1.0), 2.0);
    } else if (aoMethod < 1.5) {
        ao = pow(clamp(1.0 - totalDist / 8.0, 0.0, 1.0), 2.0);
    } else {
        float3 nFractal = float3(nx, nz, -ny);
        float ao_acc = 0.0;
        float aoStep = 0.03;
        float decay  = 1.0;
        float t_ao;
        for (int i = 1; i <= 5; i++) {
            float3 aoPos = hitPosR + nFractal * aoStep * float(i);
            float d = mb.DE(aoPos, animPower, pa, t_ao, trapMethod);
            ao_acc += decay * (aoStep * float(i) - d);
            decay *= 0.75;
        }
        ao = pow(clamp(1.0 - ao_acc * 2.0, 0.0, 1.0), 2.0);
    }

    float fresnel = pow(1.0 - abs(dot(n, viewDir3)), 20.0);

    float3 col;
    if (lightMethod < 0.5) {
        col = trapColour * (diffuse * 0.7 + fill + 0.05) * ao;
        col += float3(1.0, 0.95, 0.8) * spec * 0.8;
    } else if (lightMethod < 1.5) {
        col = trapColour * (diffuse * 0.7 + fill + 0.05) * ao;
    } else if (lightMethod < 2.5) {
        col = trapColour * fresnel * ao;
        col += float3(1.0, 0.95, 0.8) * fresnel * 0.5;
    } else {
        col = trapColour * ao * 0.8;
    }

    opacityMask = 1.0;
    return col * 3.0;
}

float glow;
float3 missOut;

if (glowStyle < 0.5) {
    glow = exp(-minDE * 40.0 * glowSharpness);
    missOut = missColour * glow * 4.0 * glowBrightness;
} else if (glowStyle < 1.5) {
    glow = exp(-minDE * 8.0 * glowSharpness);
    missOut = missColour * glow * 3.0 * glowBrightness;
} else if (glowStyle < 2.5) {
    glow = exp(-minDE * 20.0 * glowSharpness);
    float3 haloCol = lerp(missColour, trapColour, clamp(trapValue * 2.0, 0.0, 1.0));
    missOut = haloCol * glow * 4.0 * glowBrightness;
} else {
    glow = clamp(1.0 - minDE * 8.0 * glowSharpness, 0.0, 1.0);
    glow = glow * glow;
    missOut = missColour * glow * 1.5 * glowBrightness;
}

// grain
float2 seed = viewDir.xy + float2(totalDist, minDE);
float grain = frac(sin(dot(seed, float2(127.1, 311.7))) * 43758.5453);
grain = (grain - 0.5) * 0.1;
missOut += missColour * grain * glow;

opacityMask = glow;
return missOut;