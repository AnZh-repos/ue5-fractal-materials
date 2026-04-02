# ue5-fractal-materials

Three raymarched fractal materials for Unreal Engine 5 - Mandelbulb, Mandelbox, and Mandelbrot. Built as post-process materials with distance estimator-based rendering, ambient occlusion, and palette-driven color via curve atlases.

## Contents

```
uassets/          - drop into your UE5 project Content folder
  Materials/
  CurveAtlases/
  MaterialParameterCollections/
  Palettes/
    Palettes_Mandelbulb/
    Palettes_Mandelbox_Seamless/
    Palettes_Mandelbrot/

hlsl/             - extracted Custom node code, readable without UE5
  Mandelbulb/
    Mandelbulb_March.hlsl
    Mandelbulb_Shade.hlsl
  Mandelbox/
    Mandelbox_March.hlsl
    Mandelbox_Shade.hlsl
  Mandelbrot/
    Mandelbrot_Iteration.hlsl
    Mandelbrot_Shade.hlsl

ds_split.py       - splits a double-precision coordinate into float32 hi/lo pair for Mandelbrot zoom targets
```

## Requirements

- UE5.5+ (tested on UE5.7)
- All three materials require their corresponding CurveAtlas and palette curves to display color. Without the palettes the atlas lookup returns black.

## Setup

### Mandelbulb and Mandelbox

Both are surface post-process materials. Drag onto any mesh - a cube works fine for testing. Parameters are driven by their respective MPC assets.

### Mandelbrot

Post-process material applied fullscreen through a PostProcessVolume, not a mesh.

1. Place a **PostProcessVolume** in the scene
2. In Details → **Infinite Extent (Unbound)** → enable
3. In Details → **Post Process Materials** → add `M_Mandelbrot`, set blend weight to `1.0`
4. Set blendable location to **Before Bloom**
5. Open `MPC_Mandelbrot` and set `zoomExponent` to something above `5` - at `0` you see the full set zoomed out, which is mostly black border

The zoom target is hardcoded as a double-single coordinate pair (`crHi/crLo`, `ciHi/ciLo`) in the iteration node. The default points to the tip of the main cardioid. To change it, edit the target coordinates in `ds_split.py` and run it - it outputs the four constants to paste into the Custom node. Clean zoom limit is around `zoomExponent = 40`. Past that the pixel offset underflows in float32 before the DS addition and neighboring pixels collapse to the same point.

Animating `zoomExponent` in Sequencer via the MPC is how the cinematic zoom was produced.

## Parameters

All three materials share mostly the same parameter pattern. Key ones:

| Param | What it does |
|---|---|
| `zoomExponent` | Mandelbrot only - zoom depth, powers of 2. clean limit ~40 |
| `colorOffset` | Rotates palette lookup, shifts color cycle |
| `glowBrightness` | Miss-path glow intensity |
| `glowSharpness` | How tight the glow falloff is |
| `trapMethod` | Mandelbulb/Mandelbox - which primitive orbit trap measures to. changes where color lands on surface, swap palette alongside it. 0=XY plane, 1=XZ, 2=X axis, 3=sphere, 4=offset point |
| `normalMethod` | Mandelbulb/Mandelbox - which normal estimation runs. 0=adaptive (default), 1=tetrahedron, 2=central-difference, 3=forward-difference, 4=5-point stencil, 5=jittered average, 6=orbit trap gradient |
| `aoMethod` | Mandelbulb/Mandelbox - 0=step-count based, 1=distance-based, 2=DE-based cone AO |

Full descriptions of what each parameter does are in the material graph comment nodes. Wiring is kept clean so it's readable without digging into the HLSL.

## HLSL notes

The `.hlsl` files are the raw code from UE5 Custom nodes. To use them outside UE5 you'd need to wire up inputs manually - each file's input pins are listed in the corresponding material comment nodes.

Mandelbulb and Mandelbox use a two-node structure: march node outputs hit position, distance, and trap value; shade node takes those and outputs final color. Mandelbrot skips the march entirely - iteration node outputs smooth escape count, shade node maps it through the palette.

Distance estimator for Mandelbulb follows the Quilez DE derivation. Mandelbox DE uses `(abs(scale) - 1.0)` in the denominator - some implementations get this wrong and produce incorrect AO.

The DS macros in `Mandelbrot_Iteration.hlsl` use the `precise` keyword on all error terms. UE's cross-compiler applies fast-math by default which algebraically collapses the error recovery and destroys the lower bits and `precise` prevents that. Without it the double-single precision gain is lost past zoom ~30. If you're porting these outside UE5, that's the first thing to check if deep zoom looks wrong.

## Renders

All videos 4K 60fps, rendered via Movie Render Queue.

**Mandelbulb**
[![Mandelbulb](https://img.youtube.com/vi/WZrZBTUd98I/maxresdefault.jpg)](https://youtu.be/WZrZBTUd98I)

`powerBase=8, animSpeed=0.1, aoMethod=0, trapMethod=0, normalMethod=0, fractalScale=60, Palette=BlueGold`

**Mandelbox**
[![Mandelbox](https://img.youtube.com/vi/d_n2PE4XaSo/maxresdefault.jpg)](https://youtu.be/d_n2PE4XaSo)

`scaleBase=-2.0, foldLimit=0.5, innerRadius=0.5, outerRadius=1.0, animTarget=0, animSpeed=1.0, animRange=0.5, fractalScale=2400, Palette=Seamless_GoldLeaf`

**Mandelbrot**
[![Mandelbrot](https://img.youtube.com/vi/oz7AKR0AfPM/maxresdefault.jpg)](https://youtu.be/oz7AKR0AfPM)

`glowBrightness=5, glowSharpness=1, iterScale=128, Palette=Ultraviolet` — zooms to `zoomExponent=40`

Zoom target coordinates (paste into `Mandelbrot_Iteration.hlsl` or run your own through `ds_split.py`):
```
const float crHi = -0.19829005002975;
const float crLo = 7.4054087306762995e-09;
const float ciHi = -1.1009837388992;
const float ciLo = 2.3803621296281108e-08;
```
