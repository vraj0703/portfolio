"""Pack each surface's roughness and metalness into one map, ahead of time.

usage: python tool/pack_rough_metal.py            (needs Pillow)

flutter_scene reads roughness from green and metalness from blue of one
texture. The gallery used to build that texture in the browser: decode the
grey roughness map, read its pixels back, loop over a million of them in
Dart, and upload the result, on the main thread behind the loading screen.
On a 4x slower CPU that was 27 s of a 105 s build (PORTFOLIO-8). The result
never changes, so it is made here once instead.

Writes <name>_RoughMetal.webp beside each roughness map, lossless, the same
size as its source:
  R = 0 (not read by the shader)
  G = roughness (the grey map's value)
  B = metalness: the set's metalness map where it has one, else its constant
  A = 255

Only sets with metal in them are packed. A dielectric (metallic 0) loads its
grey roughness map as it is and zeroes blue with the material's factor, which
costs no bytes; see `roughMetal` in lib/presentation/gallery/texture_sets.dart.

Lossless on purpose: lossy WebP subsamples chroma, and with roughness and
metalness in different channels that smeared the keys' metal (mean error
about 20/255 in blue).

The table mirrors `packedFrom` in texture_sets.dart, and
test/presentation/gallery/texture_sets_test.dart checks every packed map
against its sources, so a drift between them fails the tests.
"""
import os
import sys

from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "textures")

# roughness map, metalness map or None, constant metallic used when there is no map
SETS = [
    ("keyboard_base/Metal048B_1K-JPG_Roughness.webp", None, 1.0),
    ("keys/set_1/Metal023_1K-JPG_Roughness.webp", "keys/set_1/Metal023_1K-JPG_Metalness.webp", 1.0),
    ("keys/set_2/Metal056B_1K-JPG_Roughness.webp", "keys/set_2/Metal056B_1K-JPG_Metalness.webp", 1.0),
    ("keys/set_3/Metal022_1K-JPG_Roughness.webp", "keys/set_3/Metal022_1K-JPG_Metalness.webp", 1.0),
]


def pack(rough_path, metal_path, metallic):
    rough = Image.open(os.path.join(ROOT, rough_path)).convert("RGB").getchannel("R")
    if metal_path:
        metal = Image.open(os.path.join(ROOT, metal_path)).convert("RGB").getchannel("R")
        if metal.size != rough.size:
            metal = metal.resize(rough.size, Image.BILINEAR)
    else:
        metal = Image.new("L", rough.size, max(0, min(255, round(metallic * 255))))
    zero = Image.new("L", rough.size, 0)
    opaque = Image.new("L", rough.size, 255)
    return Image.merge("RGBA", (zero, rough, metal, opaque))


def main():
    for rough_path, metal_path, metallic in SETS:
        out = rough_path.replace("_Roughness.webp", "_RoughMetal.webp")
        image = pack(rough_path, metal_path, metallic)
        target = os.path.join(ROOT, out)
        image.save(target, "WEBP", lossless=True, quality=100, method=6, exact=True)
        print(f"{out}: {image.size[0]}x{image.size[1]}, {os.path.getsize(target)} bytes")


if __name__ == "__main__":
    sys.exit(main())
