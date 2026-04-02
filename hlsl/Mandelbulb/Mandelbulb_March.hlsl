struct MandelbulbFunctions {

    float DE(float3 p, float pw, float pa, out float trap, float trapMethod) {
        float3 z = p;
        float dr = 1.0;
        float r  = 0.0;
        trap = 1000.0;

        for (int i = 0; i < 128; i++) {
            r = length(z);

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

            if (r < 0.0001 || r > 2.0) break;

            // spherical coordinates + power fold
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

    float3 normal(float3 p, float pw, float pa, float method, float td, float trapMethod) {
        float t;
        float3 n;

        if (method < 0.5) {
            // adaptive central differences - eps scales with ray distance
            float eps = 0.0001 + (td * 0.0005);
            n = normalize(float3(
                DE(p+float3(eps,0,0),pw,pa,t,trapMethod) - DE(p-float3(eps,0,0),pw,pa,t,trapMethod),
                DE(p+float3(0,eps,0),pw,pa,t,trapMethod) - DE(p-float3(0,eps,0),pw,pa,t,trapMethod),
                DE(p+float3(0,0,eps),pw,pa,t,trapMethod) - DE(p-float3(0,0,eps),pw,pa,t,trapMethod)
            ));
        } else if (method < 1.5) {
            // tetrahedron method - 4 samples instead of 6
            float eps = 0.001;
            float2 k = float2(1.0, -1.0);
            n = normalize(
                k.xyy * DE(p + k.xyy*eps, pw, pa, t, trapMethod) +
                k.yyx * DE(p + k.yyx*eps, pw, pa, t, trapMethod) +
                k.yxy * DE(p + k.yxy*eps, pw, pa, t, trapMethod) +
                k.xxx * DE(p + k.xxx*eps, pw, pa, t, trapMethod)
            );
        } else if (method < 2.5) {
            // standard 6-sample central differences
            float eps = 0.001;
            n = normalize(float3(
                DE(p+float3(eps,0,0),pw,pa,t,trapMethod) - DE(p-float3(eps,0,0),pw,pa,t,trapMethod),
                DE(p+float3(0,eps,0),pw,pa,t,trapMethod) - DE(p-float3(0,eps,0),pw,pa,t,trapMethod),
                DE(p+float3(0,0,eps),pw,pa,t,trapMethod) - DE(p-float3(0,0,eps),pw,pa,t,trapMethod)
            ));
        } else if (method < 3.5) {
            // forward differences - cheapest, 3+1 samples
            float eps = 0.001;
            float d0 = DE(p, pw, pa, t, trapMethod);
            n = normalize(float3(
                DE(p+float3(eps,0,0),pw,pa,t,trapMethod) - d0,
                DE(p+float3(0,eps,0),pw,pa,t,trapMethod) - d0,
                DE(p+float3(0,0,eps),pw,pa,t,trapMethod) - d0
            ));
        } else if (method < 4.5) {
            // higher-order 5-point stencil - smoother normals, expensive
            float h = 0.001;
            float3 acc = float3(0,0,0);
            for (int i = 0; i < 3; i++) {
                float3 v1 = p, v2 = p, v3 = p, v4 = p;
                v1[i] += 2.0*h; v2[i] += h; v3[i] -= h; v4[i] -= 2.0*h;
                acc[i] = (-DE(v1,pw,pa,t,trapMethod) + 8.0*DE(v2,pw,pa,t,trapMethod) - 8.0*DE(v3,pw,pa,t,trapMethod) + DE(v4,pw,pa,t,trapMethod)) / (12.0*h);
            }
            n = normalize(acc);
        } else if (method < 5.5) {
            // jittered average - softens sharp creases
            float eps = 0.001;
            float3 jitter = float3(0.0, 0.0013, -0.0013);
            float3 n1 = normalize(float3(
                DE(p+float3(eps,0,0),pw,pa,t,trapMethod) - DE(p-float3(eps,0,0),pw,pa,t,trapMethod),
                DE(p+float3(0,eps,0),pw,pa,t,trapMethod) - DE(p-float3(0,eps,0),pw,pa,t,trapMethod),
                DE(p+float3(0,0,eps),pw,pa,t,trapMethod) - DE(p-float3(0,0,eps),pw,pa,t,trapMethod)
            ));
            float3 pj = p + jitter;
            float3 n2 = normalize(float3(
                DE(pj+float3(eps,0,0),pw,pa,t,trapMethod) - DE(pj-float3(eps,0,0),pw,pa,t,trapMethod),
                DE(pj+float3(0,eps,0),pw,pa,t,trapMethod) - DE(pj-float3(0,eps,0),pw,pa,t,trapMethod),
                DE(pj+float3(0,0,eps),pw,pa,t,trapMethod) - DE(pj-float3(0,0,eps),pw,pa,t,trapMethod)
            ));
            float3 pj2 = p - jitter;
            float3 n3 = normalize(float3(
                DE(pj2+float3(eps,0,0),pw,pa,t,trapMethod) - DE(pj2-float3(eps,0,0),pw,pa,t,trapMethod),
                DE(pj2+float3(0,eps,0),pw,pa,t,trapMethod) - DE(pj2-float3(0,eps,0),pw,pa,t,trapMethod),
                DE(pj2+float3(0,0,eps),pw,pa,t,trapMethod) - DE(pj2-float3(0,0,eps),pw,pa,t,trapMethod)
            ));
            n = normalize(n1 + n2 + n3);
        } else {
            // orbit trap gradient - normal derived from trap field, not geometry
            float eps = 0.001;
            float t1, t2, t3, t4, t5, t6;
            DE(p+float3(eps,0,0),pw,pa,t1,trapMethod); DE(p-float3(eps,0,0),pw,pa,t2,trapMethod);
            DE(p+float3(0,eps,0),pw,pa,t3,trapMethod); DE(p-float3(0,eps,0),pw,pa,t4,trapMethod);
            DE(p+float3(0,0,eps),pw,pa,t5,trapMethod); DE(p-float3(0,0,eps),pw,pa,t6,trapMethod);
            n = normalize(float3(t1-t2, t3-t4, t5-t6));
        }
        return n;
    }
};
MandelbulbFunctions mb;

// UE world space → fractal local space
float3 wp = worldPos / fractalScale;
float3 rayStep = normalize(-viewDir);
animPower = powerBase;
float polarAngle = sin(time * animSpeed) * 3.14159265;

totalDist  = 0.0;
stepsTaken = 0;
trapValue  = 0.0;
minDE      = 1000.0;
hit        = 0.0;

for (int i = 0; i < 256; i++) {
    float3 pos  = wp + rayStep * totalDist;
    // reorient from UE (x-forward, z-up) to fractal convention (z-forward, y-up)
    float3 posR = float3(pos.x, pos.z, -pos.y);
    float  dist = mb.DE(posR, animPower, polarAngle, trapValue, trapMethod);
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
    float3 nFractal = mb.normal(hitPosR, animPower, polarAngle, normalMethod, totalDist, trapMethod);
    // rotate normal back to UE space
    float3 n = float3(nFractal.x, -nFractal.z, nFractal.y);
    nx = n.x; ny = n.y; nz = n.z;
    hit = 1.0;
}

return hitPosR;