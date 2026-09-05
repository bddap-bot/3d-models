#!/usr/bin/env nix-shell
#!nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/71caefce12ba78d84fe618cf61644dce01cf3a96.tar.gz -i python3 -p openscad xvfb-run "python3.withPackages (p: [p.pillow])"
import subprocess
from pathlib import Path

from PIL import Image, ImageChops

HERE = Path(__file__).resolve().parent
VIEWS = {
    "seam": ("seam", 0, ["--camera=0,0,120,0,0,0,400", "--projection=o"]),
    "seam_corner": ("seam_corner", 0, ["--camera=66,-4,120,0,0,0,60", "--projection=o"]),
    "window_corner": ("window_corner", 0, ["--camera=66,2,1.5,0,0,0,60", "--projection=o"]),
    "groove": ("groove", 0, ["--camera=66,30,25,90,0,90,560", "--projection=o"]),
    "groove_dropped": ("groove", 12, ["--camera=66,30,25,90,0,90,560", "--projection=o"]),
    "perch_section": ("perch_section", 0, ["--camera=30,60,0,90,0,90,320", "--projection=o"]),
    "perch_axis": ("perch_axis", 0, ["--camera=0,0,0,70,0,140,0", "--viewall", "--autocenter"]),
    "bracket_print": ("bracket_print", 0, ["--camera=0,0,0,65,0,35,0", "--viewall", "--autocenter"]),
}
for name, (view, drop, camera) in VIEWS.items():
    png = HERE / f"{name}.png"
    subprocess.run(["xvfb-run", "-a", "openscad", "-q", "-o", str(png), f'-Dview="{view}"', f"-Ddrop={drop}", *camera, "--imgsize=1400,1000", str(HERE / "hands-on.scad")], check=True)
    im = Image.open(png).convert("RGB")
    x0, y0, x1, y1 = ImageChops.difference(im, Image.new("RGB", im.size, im.getpixel((0, 0)))).getbbox()
    im.crop((max(0, x0 - 30), max(0, y0 - 30), min(im.width, x1 + 30), min(im.height, y1 + 30))).save(png, optimize=True)
