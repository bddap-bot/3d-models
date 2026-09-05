import glob
from PIL import Image, ImageChops
for f in glob.glob("img_*.png"):
    im = Image.open(f).convert("RGB")
    bg = Image.new("RGB", im.size, im.getpixel((0,0)))
    box = ImageChops.difference(im, bg).getbbox()
    if box:
        m = 30
        box = (max(0,box[0]-m), max(0,box[1]-m), min(im.width,box[2]+m), min(im.height,box[3]+m))
        im.crop(box).save(f)
