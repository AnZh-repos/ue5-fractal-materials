struct MandelboxFunctions {

    float DE(float3 p, float scale, float foldLimit, float innerRadius, float outerRadius, out float trap, float trapMethod) {
        float3 z  = p;
        float  dr = 1.0;
        trap = 1000.0;

        float innerR2 = innerRadius * innerRadius;
        float outerR2 = outerRadius * outerRadius;
        float innerScale = outerR2 / innerR2;
        float bailout2 = 1000;

        for (int i = 0; i < 128; i++) {

            // orbit trap
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

            // box fold
            z = clamp(z, -foldLimit, foldLimit) * 2.0 - z;

            // sphere fold
            float r2 = dot(z, z);
            if (r2 < innerR2) {
                z  *= innerScale;
                dr *= innerScale;
            } else if (r2 < outerR2) {
                float temp = outerR2 / r2;
                z  *= temp;
                dr *= temp;
            }

            z  = z * scale + p;
            dr = dr * abs(scale) + 1.0;

            if (dot(z, z) > bailout2) break;
        }

        return (length(z) - abs(scale - 1.0)) / dr;
    }

    float3 normal(float3 p, float scale, float foldLimit, float innerRadius, float outerRadius, float method, float td, float trapMethod) {
        float t;
        float3 n;

        if (method < 0.5) {
            float eps = 0.0001 + (td * 0.0005);
            n = normalize(float3(
                DE(p+float3(eps,0,0),scale,foldLimit,innerRadius,outerRadius,t,trapMethod) - DE(p-float3(eps,0,0),scale,foldLimit,innerRadius,outerRadius,t,trapMethod),
                DE(p+float3(0,eps,0),scale,foldLimit,innerRadius,outerRadius,t,trapMethod) - DE(p-float3(0,eps,0),scale,foldLimit,innerRadius,outerRadius,t,trapMethod),
                DE(p+float3(0,0,eps),scale,foldLimit,innerRadius,outerRadius,t,trapMethod) - DE(p-float3(0,0,eps),scale,foldLimit,innerRadius,outerRadius,t,trapMethod)
            ));
        } else if (method < 1.5) {
            float eps = 0.001;
            float2 k = float2(1.0, -1.0);
            n = normalize(
                k.xyy * DE(p + k.xyy*eps, scale, foldLimit, innerRadius, outerRadius, t, trapMethod) +
                k.yyx * DE(p + k.yyx*eps, scale, foldLimit, innerRadius, outerRadius, t, trapMethod) +
                k.yxy * DE(p + k.yxy*eps, scale, foldLimit, innerRadius, outerRadius, t, trapMethod) +
                k.xxx * DE(p + k.xxx*eps, scale, foldLimit, innerRadius, outerRadius, t, trapMethod)
            );
        } else if (method < 2.5) {
            float eps = 0.001;
            n = normalize(float3(
                DE(p+float3(eps,0,0),scale,foldLimit,innerRadius,outerRadius,t,trapMethod) - DE(p-float3(eps,0,0),scale,foldLimit,innerRadius,outerRadius,t,trapMethod),
                DE(p+float3(0,eps,0),scale,foldLimit,innerRadius,outerRadius,t,trapMethod) - DE(p-float3(0,eps,0),scale,foldLimit,innerRadius,outerRadius,t,trapMethod),
                DE(p+float3(0,0,eps),scale,foldLimit,innerRadius,outerRadius,t,trapMethod) - DE(p-float3(0,0,eps),scale,foldLimit,innerRadius,outerRadius,t,trapMethod)
            ));
        } else if (method < 3.5) {
            float eps = 0.001;
            float d0 = DE(p, scale, foldLimit, innerRadius, outerRadius, t, trapMethod);
            n = normalize(float3(
                DE(p+float3(eps,0,0),scale,foldLimit,innerRadius,outerRadius,t,trapMethod) - d0,
                DE(p+float3(0,eps,0),scale,foldLimit,innerRadius,outerRadius,t,trapMethod) - d0,
                DE(p+float3(0,0,eps),scale,foldLimit,innerRadius,outerRadius,t,trapMethod) - d0
            ));
        } else if (method < 4.5) {
            float h = 0.001;
            float3 acc = float3(0,0,0);
            for (int i = 0; i < 3; i++) {
                float3 v1 = p, v2 = p, v3 = p, v4 = p;
                v1[i] += 2.0*h; v2[i] += h; v3[i] -= h; v4[i] -= 2.0*h;
                acc[i] = (-DE(v1,scale,foldLimit,innerRadius,outerRadius,t,trapMethod) + 8.0*DE(v2,scale,foldLimit,innerRadius,outerRadius,t,trapMethod) - 8.0*DE(v3,scale,foldLimit,innerRadius,outerRadius,t,trapMethod) + DE(v4,scale,foldLimit,innerRadius,outerRadius,t,trapMethod)) / (12.0*h);
            }
            n = normalize(acc);
        } else if (method < 5.5) {
            float eps = 0.001;
            float3 jitter = float3(0.0, 0.0013, -0.0013);
            float3 n1 = normalize(float3(
                DE(p+float3(eps,0,0),scale,foldLimit,innerRadius,outerRadius,t,trapMethod) - DE(p-float3(eps,0,0),scale,foldLimit,innerRadius,outerRadius,t,trapMethod),
                DE(p+float3(0,eps,0),scale,foldLimit,innerRadius,outerRadius,t,trapMethod) - DE(p-float3(0,eps,0),scale,foldLimit,innerRadius,outerRadius,t,trapMethod),
                DE(p+float3(0,0,eps),scale,foldLimit,innerRadius,outerRadius,t,trapMethod) - DE(p-float3(0,0,eps),scale,foldLimit,innerRadius,outerRadius,t,trapMethod)
            ));
            float3 pj = p + jitter;
            float3 n2 = normalize(float3(
                DE(pj+float3(eps,0,0),scale,foldLimit,innerRadius,outerRadius,t,trapMethod) - DE(pj-float3(eps,0,0),scale,foldLimit,innerRadius,outerRadius,t,trapMethod),
                DE(pj+float3(0,eps,0),scale,foldLimit,innerRadius,outerRadius,t,trapMethod) - DE(pj-float3(0,eps,0),scale,foldLimit,innerRadius,outerRadius,t,trapMethod),
                DE(pj+float3(0,0,eps),scale,foldLimit,innerRadius,outerRadius,t,trapMethod) - DE(pj-float3(0,0,eps),scale,foldLimit,innerRadius,outerRadius,t,trapMethod)
            ));
            float3 pj2 = p - jitter;
            float3 n3 = normalize(float3(
                DE(pj2+float3(eps,0,0),scale,foldLimit,innerRadius,outerRadius,t,trapMethod) - DE(pj2-float3(eps,0,0),scale,foldLimit,innerRadius,outerRadius,t,trapMethod),
                DE(pj2+float3(0,eps,0),scale,foldLimit,innerRadius,outerRadius,t,trapMethod) - DE(pj2-float3(0,eps,0),scale,foldLimit,innerRadius,outerRadius,t,trapMethod),
                DE(pj2+float3(0,0,eps),scale,foldLimit,innerRadius,outerRadius,t,trapMethod) - DE(pj2-float3(0,0,eps),scale,foldLimit,innerRadius,outerRadius,t,trapMethod)
            ));
            n = normalize(n1 + n2 + n3);
        } else {
            float eps = 0.001;
            float t1, t2, t3, t4, t5, t6;
            DE(p+float3(eps,0,0),scale,foldLimit,innerRadius,outerRadius,t1,trapMethod); DE(p-float3(eps,0,0),scale,foldLimit,innerRadius,outerRadius,t2,trapMethod);
            DE(p+float3(0,eps,0),scale,foldLimit,innerRadius,outerRadius,t3,trapMethod); DE(p-float3(0,eps,0),scale,foldLimit,innerRadius,outerRadius,t4,trapMethod);
            DE(p+float3(0,0,eps),scale,foldLimit,innerRadius,outerRadius,t5,trapMethod); DE(p-float3(0,0,eps),scale,foldLimit,innerRadius,outerRadius,t6,trapMethod);
            n = normalize(float3(t1-t2, t3-t4, t5-t6));
        }
        return n;
    }
};
MandelboxFunctions mb;

float3 wp      = worldPos / fractalScale;
float3 rayStep = normalize(-viewDir);

// animTarget: 0 = scale, 1 = foldLimit, 2 = innerRadius, 3 = outerRadius
float anim = sin(time * animSpeed) * animRange;

float activeScale       = scaleBase;
float activeFoldLimit   = foldLimit;
float activeInnerRadius = innerRadius;
float activeOuterRadius = outerRadius;

if (animTarget < 0.5) {
    activeScale       = scaleBase + anim;
} else if (animTarget < 1.5) {
    activeFoldLimit   = foldLimit + anim * 0.3;
} else if (animTarget < 2.5) {
    activeInnerRadius = clamp(innerRadius + anim * 0.2, 0.01, activeOuterRadius - 0.01);
} else {
    activeOuterRadius = clamp(outerRadius + anim * 0.2, activeInnerRadius + 0.01, 2.0);
}

animScale = activeScale;  // write back for shade node

totalDist  = 0.0;
stepsTaken = 0;
trapValue  = 0.0;
minDE      = 1000.0;
hit        = 0.0;

for (int i = 0; i < 256; i++) {
    float3 pos  = wp + rayStep * totalDist;
    float3 posR = float3(pos.x, pos.z, -pos.y);
    float  dist = mb.DE(posR, activeScale, activeFoldLimit, activeInnerRadius, activeOuterRadius, trapValue, trapMethod);
    minDE       = min(minDE, dist);
    totalDist  += max(dist, 0.0001);
    stepsTaken  = i;
    if (dist < 0.0002 || totalDist > 500.0) break;
}

float3 hitPosR = float3(0,0,0);
nx = 0.0; ny = 0.0; nz = 0.0;

if (totalDist < 500.0) {
    float3 hitPos = wp + rayStep * totalDist;
    hitPosR = float3(hitPos.x, hitPos.z, -hitPos.y);
    float3 nFractal = mb.normal(hitPosR, activeScale, activeFoldLimit, activeInnerRadius, activeOuterRadius, normalMethod, totalDist, trapMethod);
    float3 n = float3(nFractal.x, -nFractal.z, nFractal.y);
    nx = n.x; ny = n.y; nz = n.z;
    hit = 1.0;
}

return hitPosR;