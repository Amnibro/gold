# key ;; verb ;; noun ;; modifier ;; slots ;; phrases (//) ;; tests (;;)
canvas ;; start ;; texture ;; canvas ;; w:int h:int ;; start a blank texture {w} by {h} pixels // new image canvas {w} wide {h} tall ;; w=16 h=16 ;; w=8 h=4 ;; w=64 h=64
fill ;; fill ;; texture ;; value ;; a:real ;; fill the texture with value {a} // set every pixel to {a} ;; img=8 a=0.25 ;; img=16 a=0.75 ;; a=0.3
noise ;; fill ;; texture ;; noise ;; c:int u:int ;; fill the texture with value noise of cell {c} seed {u} // tileable noise with cells of {c} pixels using seed {u} ;; img=16 c=4 u=7 ;; img=32 c=8 u=3 ;; img=16 c=5 u=1
fbm ;; layer ;; texture ;; fractal ;; n:int c:int u:int ;; layer {n} octaves of noise from cell {c} seed {u} // fractal noise with {n} octaves base cell {c} seed {u} ;; img=32 n=3 c=16 u=5 ;; img=16 n=2 c=8 u=9 ;; img=16 n=6 c=8 u=1
worley ;; fill ;; texture ;; cellular ;; c:int u:int ;; fill the texture with cellular noise of cell {c} seed {u} // voronoi cells of {c} pixels using seed {u} ;; img=16 c=4 u=2 ;; img=32 c=8 u=6 ;; img=16 c=3 u=2
checker ;; paint ;; texture ;; checker ;; c:int ;; paint a checkerboard with squares of {c} pixels // checker pattern of cell size {c} ;; img=16 c=4 ;; img=8 c=1 ;; c=2
stripes ;; paint ;; texture ;; stripes ;; c:int ;; paint vertical stripes {c} pixels wide // stripe pattern with bands of {c} pixels ;; img=16 c=2 ;; img=8 c=3 ;; img=8 c=0
hgrad ;; fill ;; texture ;; hgradient ;; - ;; fill the texture with a horizontal gradient // ramp from dark on the left to bright on the right ;; img=16 ;; img=8 ;; -
vgrad ;; fill ;; texture ;; vgradient ;; - ;; fill the texture with a vertical gradient // ramp from dark at the top to bright at the bottom ;; img=16 ;; img=4 ;; -
radial ;; fill ;; texture ;; radial ;; - ;; fill the texture with a radial falloff // bright center fading to dark edges ;; img=16 ;; img=9 ;; -
invert ;; invert ;; texture ;; tone ;; - ;; invert the texture // flip dark pixels to bright ;; img=16 ;; img=8 ;; -
threshold ;; threshold ;; texture ;; mask ;; a:real ;; threshold the texture at {a} // turn pixels brighter than {a} white ;; img=16 a=0.4 ;; img=8 a=0.7 ;; a=0.5
contrast ;; raise ;; texture ;; contrast ;; a:real ;; raise texture contrast by factor {a} // stretch contrast around middle grey by {a} ;; img=16 a=1.8 ;; img=8 a=0.6 ;; a=2.0
brighten ;; brighten ;; texture ;; brightness ;; a:real ;; brighten the texture by {a} // add {a} to every pixel ;; img=16 a=0.2 ;; img=8 a=0.35 ;; a=0.1
darken ;; darken ;; texture ;; darkness ;; a:real ;; darken the texture by {a} // subtract {a} from every pixel ;; img=16 a=0.2 ;; img=8 a=0.45 ;; a=0.1
scale ;; scale ;; texture ;; gain ;; a:real ;; scale texture brightness by {a} // multiply every pixel by {a} ;; img=16 a=1.3 ;; img=8 a=0.4 ;; a=2.0
blur ;; blur ;; texture ;; box ;; - ;; blur the texture // soften the texture with a box blur ;; img=16 ;; img=8 ;; -
normalize ;; normalize ;; texture ;; range ;; - ;; normalize the texture to full range // stretch pixel values across the full range ;; img=16 ;; img=4 ;; -
quantize ;; posterize ;; texture ;; levels ;; n:int ;; posterize the texture into {n} levels // reduce the texture to {n} grey steps ;; img=16 n=4 ;; img=8 n=2 ;; img=8 n=1
mirror ;; mirror ;; texture ;; horizontal ;; - ;; mirror the texture horizontally // flip the texture left to right ;; img=16 ;; img=8 ;; -
flip ;; flip ;; texture ;; vertical ;; - ;; flip the texture vertically // turn the texture upside down ;; img=16 ;; img=8 ;; -
remap ;; remap ;; texture ;; window ;; a:real b:real ;; remap the texture between {a} and {b} // squeeze pixel values into range {a} to {b} ;; img=16 a=0.2 b=0.8 ;; img=8 a=0.9 b=0.1 ;; a=0.2 b=0.6
slope ;; derive ;; texture ;; roughness ;; - ;; derive roughness from texture slope // turn the height texture into a slope map ;; img=16 ;; img=8 ;; -
seam ;; measure ;; texture ;; seam ;; - ;; measure the texture seam // check how well the texture tiles ;; img=16 ;; img=8 ;; -
