import subprocess
from pathlib import Path

from PIL import Image, ImageChops

HERE = Path(__file__).resolve().parent
VIEWS = {
    "seam": ("seam", 0, "0,0,120,0,0,0,400", "o"),
    "seam_corner": ("seam_corner", 0, "66,-4,120,0,0,0,60", "o"),
    "window_corner": ("window_corner", 0, "66,2,1.5,0,0,0,60", "o"),
    "groove": ("groove", 0, "66,30,25,90,0,90,560", "o"),
    "groove_dropped": ("groove", 12, "66,30,25,90,0,90,560", "o"),
    "perch_section": ("perch_section", 0, "30,60,0,90,0,90,320", "o"),
    "perch_axis": ("perch_axis", 0, "0,40,0,70,0,140,470", "p"),
    "bracket_print": ("bracket_print", 0, "0,0,80,65,0,35,470", "p"),
}
for name, (view, drop, camera, proj) in VIEWS.items():
    png = HERE / f"{name}.png"
    fit = ["--viewall", "--autocenter"] if proj == "p" else []
    subprocess.run(["xvfb-run", "-a", "openscad", "-q", "-o", str(png), f'-Dview="{view}"', f"-Ddrop={drop}", f"--camera={camera}", f"--projection={proj}", *fit, "--imgsize=1400,1000", str(HERE / "hands-on.scad")], check=True)
    im = Image.open(png).convert("RGB")
    box = ImageChops.difference(im, Image.new("RGB", im.size, im.getpixel((0, 0)))).getbbox()
    if box and not name.endswith("_corner"):
        im = im.crop((max(0, box[0] - 30), max(0, box[1] - 30), min(im.width, box[2] + 30), min(im.height, box[3] + 30)))
    im.save(png, optimize=True)
