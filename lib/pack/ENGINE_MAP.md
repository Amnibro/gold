# Gold scene phrases → engine concepts

This is the contract a Helium gfx core (scene, material and light layer) can consume. Every scene, env, char or cad phrase compiles to one or more **Amni-Form lines**. Amni-Form is Amni-CAD's model language: Z-up, meters, angles in degrees, one item per line `name kind args… [modifiers]`. A consumer only needs a Form-line reader; Gold itself stays engine-agnostic. form_build.mjs (Mosaic) is the reference consumer and the golden-data oracle. On glTF export it converts to Y-up, which tools/scene_chains.sh checks as doc Z extent == glTF Y extent.

| engine concept | Gold nouns (count) | Form line shape (example produced by a pack entry) | consumer notes |
|---|---|---|---|
| Scene node / transform | shape (30), empty (1) | `ramp3 wedge 3,0,0.25 1,2,0.5`, `target3 empty 0,0,2`, `crate box 1,2,.5 1,1,1 rot15,0,0` | name = node id (prefix + line number). Meters; `rot` = Euler degrees, Z-up |
| Mesh primitive | shape | sphere, ellipsoid, box, capsule, cyl, cone, torus, prism, pyramid, wedge, tube, lathe, extrude | SDF primitives, so the consumer may mesh or raymarch them. `r` = radius (on a box, corner rounding) |
| CSG / modifiers | shape: subtract, intersect, smooth blend, shell, offset, twist, bend, taper, mirror, array, radial | `-` subtract, `&` intersect, `~0.1` smooth blend, `sh0.02` shell, `o0.1` offset, `tw90` twist, `bn45` bend, `tp0.2` taper, `a6:0.5,0,0` linear array, `ra6` radial array | ordered: a line combines with the lines above it |
| Instancing / scatter | env scatter (trees, rocks, grass) | expands to N explicit item lines, using a deterministic seeded jitter | instancing is the consumer's choice: identical kind+size lines can share one mesh |
| Terrain | env terrain (19) | `ground1 box 0,0,-.5 40,40,1`, `hill2 ellipsoid …`, `crater3 sphere … -`, `nz.05:.3` (noise displacement) | no heightfield primitive yet; terrain is SDF slabs plus CSG |
| Material (PBR preset) | material (16) | `m:chrome`, `m:glass`, `m:rough`, `m:emissive`, `#rrggbb` | presets map to metallic/roughness/transmission/emission. `#hex` = base colour |
| Light | light (15), scene/studio | `area3 light area 0,0,3.5 w250 sz1.5,1.5`, `rim5 light spot 0,4,3 0,0,1 w120 c40`, `lamp1 light point 1,1,2 w200 k2700`, sun | `w` = watts, `c` = spot cone in degrees, `sz` = area size, `k` = kelvin. Colour comes from `#hex` or kelvin |
| Camera | camera (16) | `front3 camera 0,-10,0.8 0,0,0.8` (eye then target), `mm85` lens, `sw36` sensor width, `cl0.5,50` clip range, `or25` ortho scale, `@camera wide` (active), `@markers 0:wide 1:wide` (cuts) | look-at camera; mm = focal length |
| Skeleton / bone | char bone (6) | `shin4L bone .12,0,0.4 .12,0,.05 ^thigh3L` (head, tail, ^parent) | names ending in L get mirrored R twins. `@bone` attaches a shape to a bone (skinning by rigid parent) |
| IK / constraints | char constraint (9) | `ik3 ik armL 1,0,0.5`, track-to, copy rotation, limit x/z, `.inf anim` (influence) | FABRIK/IK chains target a point or an empty |
| Animation track | track (11), light/camera animate | `post.loc anim 0:0,0,0 1:0,2,0.5`, `.rot anim … loop`, `linear`, `sun1.cone anim 0:45 1:10` | `item.channel anim t:value …`. Channels: loc, rot, scale and any numeric light/camera param |
| Action / clip / NLA strip | action (5) | `nod:armL.rot anim …` (named action), `strip4 strip wave at1.5 n1` | `action:bone.channel` groups keys into clips; strips schedule them (start, repeat, speed) |
| Timeline | timeline (4) | `@fps 30`, `@len 2.5`, `@start 1`, `@gltf cubic\|linear\|quat` | global `@` lines. glTF sampling choice |
| Scene globals | scene (2) | `@mirror x` | applies to the whole doc |
| CAD part | cad part (13) | `plate3 extrude 0,0,0 -0.1,-0.1 … h0.01`, `holes3 cyl … - a3:…`, gear teeth `ra18`, `bushing6 lathe …` | same Form lines, at mm-scale dimensions in meters |
| Texture (procedural) | texture (24) | not Form: a grey image buffer (≤32x32) with noise, fbm, worley, checker, stripes, gradients, tone ops, blur, slope→roughness, seam metric | the consumer maps it to a material texture slot. Export to PNG is not wired yet |

Golden checks: the exact doc text per test (pack expects), form_build check plus build mesh stats per test (golden/scene_e2e.tsv, 299 jobs), and for the 4 chains the GLB/STL structure plus 4-view review PNG sha (tests/scene_chains/golden.tsv).
