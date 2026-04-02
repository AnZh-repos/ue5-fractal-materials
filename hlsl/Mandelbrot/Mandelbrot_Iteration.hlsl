float2 uv = screenUV.xy - 0.5;
float2 ViewSize = View.ViewSizeAndInvSize.xy;
uv.x *= ViewSize.x / ViewSize.y;
float zoom  = pow(2.0, zoomExponent);
float scale = 3.5 / zoom;

// DS inline macros - precise required, fast-math will collapse error terms otherwise
#define DS_ADD(ax,ay,bx,by,rx,ry) { precise float _t1=(ax)+(bx); precise float _e=_t1-(ax); precise float _t2=(((bx)-_e)+((ax)-(_t1-_e)))+(ay)+(by); rx=_t1+_t2; ry=_t2-(rx-_t1); }
#define DS_MUL(ax,ay,bx,by,rx,ry) { const float sp=4097.0; precise float _ca=(ax)*sp; precise float _cb=(bx)*sp; precise float _a1=_ca-(_ca-(ax)); precise float _b1=_cb-(_cb-(bx)); precise float _a2=(ax)-_a1; precise float _b2=(bx)-_b1; rx=(ax)*(bx); ry=_a1*_b1-rx+_a1*_b2+_a2*_b1+_a2*_b2+(ax)*(by)+(ay)*(bx); }
#define DS_SQR(ax,ay,rx,ry) { const float sp=4097.0; precise float _ca=(ax)*sp; precise float _a1=_ca-(_ca-(ax)); precise float _a2=(ax)-_a1; rx=(ax)*(ax); ry=_a1*_a1-rx+2.0*_a1*_a2+_a2*_a2+2.0*(ax)*(ay); }

// zoom target — update with ds_split.py when changing location
const float crHi = -0.19829005002975;
const float crLo = 7.4054087306762995e-09;
const float ciHi = -1.1009837388992;
const float ciLo = 2.3803621296281108e-08;

float crx, cry, cix, ciy;

// pixel offset low part is 0.0 — pixelOffset is already float32, no hidden bits to extract
float pixelOffsetX = uv.x * scale;
DS_ADD(crHi, crLo, pixelOffsetX, 0.0, crx, cry)

float pixelOffsetY = uv.y * scale;
DS_ADD(ciHi, ciLo, pixelOffsetY, 0.0, cix, ciy)

int maxIter = clamp(int(128.0 + zoomExponent * iterScale), 128, 2048);
float zrx=0.0, zry=0.0, zix=0.0, ziy=0.0;
escaped = 0.0;
glowVal  = 0.0;

[loop]
for (int i = 0; i < maxIter; i++) {
    float zr2x, zr2y, zi2x, zi2y;
    DS_SQR(zrx, zry, zr2x, zr2y)
    DS_SQR(zix, ziy, zi2x, zi2y)
    if (zr2x + zi2x > 65536.0) {
        float log_zn = log(zr2x + zi2x) * 0.5;
        float nu = log(log_zn / log(2.0)) / log(2.0);
        glowVal = float(i) + 1.0 - nu;
        escaped = 1.0;
        break;
    }
    float zrzix, zrziy;
    DS_MUL(zrx, zry, zix, ziy, zrzix, zrziy)
    float tmp1x, tmp1y, zrnx, zrny;
    DS_ADD(zr2x, zr2y, -zi2x, -zi2y, tmp1x, tmp1y)
    DS_ADD(tmp1x, tmp1y, crx, cry, zrnx, zrny)
    float zinx, ziny;
    DS_ADD(2.0*zrzix, 2.0*zrziy, cix, ciy, zinx, ziny)
    zrx=zrnx; zry=zrny; zix=zinx; ziy=ziny;
}

return sin(glowVal * 0.1 * 3.14159 + colorOffset) * 0.5 + 0.5;