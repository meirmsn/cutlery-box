#!/usr/bin/env python3
"""Compose the GitHub social preview and README hero image (1280 x 640): the six
pieces of the model on the left, the printed box in use on the right, under a one-line title. Needs Pillow; uses DejaVu
Sans if installed, else Pillow's default font.

  python3 tools/render_stl.py render.png stl/ --px 1400 --elev 62 --azim 8 --explode 14 \\
      --colors '#c79a4c:#72bb7e' '#c4524f:#e2895c' '#4f9a62:#3a7fa6' \\
               '#3c5aa6:#b84c9c' '#2f5aa0:#8d50a3' '#c24c50:#e2895c'
  python3 tools/make_social_preview.py render.png photos/final-layout.jpg docs/social-preview.png

The --colors order follows the files in stl/: fork A, fork B, knife A, knife B,
spoon A, spoon B, each as BOTTOM:TOP, picked by eye from the photos. Take the
photo from roughly the same angle (from above, finger-notch side nearest,
narrow compartment on the left). --crop L T R B picks the part of the photo to use;
by default the centre 4:3 is used.
"""
import argparse
from PIL import Image, ImageChops, ImageDraw, ImageFont

W, H = 1280, 640
PW, PH = 600, 450            # each panel, 4:3
TOP = 150                    # panels start here; the title sits above
FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
FONT_B = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'


def fit(im, w, h, bg):
    im = im.copy(); im.thumbnail((w, h), Image.LANCZOS)
    out = Image.new('RGB', (w, h), bg); out.paste(im, ((w - im.width) // 2, (h - im.height) // 2))
    return out


def cover(im, w, h):
    s = max(w / im.width, h / im.height)
    im = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
    l, t = (im.width - w) // 2, (im.height - h) // 2
    return im.crop((l, t, l + w, t + h))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('render'); ap.add_argument('photo'); ap.add_argument('out')
    ap.add_argument('--crop', type=int, nargs=4, metavar=('L', 'T', 'R', 'B'))
    ap.add_argument('--title', default='Cutlery Box')
    ap.add_argument('--subtitle', default='Designed in OpenSCAD with Claude, printed in six pieces on a 120 mm printer')
    a = ap.parse_args()

    bg = (255, 255, 255)
    r = Image.open(a.render).convert('RGB')
    box = ImageChops.difference(r, Image.new('RGB', r.size, bg)).getbbox()
    r = fit(r.crop(box), PW - 30, PH - 30, bg)
    p = Image.open(a.photo).convert('RGB')
    if a.crop:
        p = p.crop(tuple(a.crop))
    p = cover(p, PW, PH)

    out = Image.new('RGB', (W, H), bg)
    gap = (W - 2 * PW) // 3
    out.paste(fit(r, PW, PH, bg), (gap, TOP))
    out.paste(p, (2 * gap + PW, TOP))
    d = ImageDraw.Draw(out)
    def font(path, size):
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            return ImageFont.load_default(size)
    d.text((W // 2, 62), a.title, fill=(40, 40, 40), font=font(FONT_B, 44), anchor='mm')
    d.text((W // 2, 112), a.subtitle, fill=(100, 100, 100), font=font(FONT, 22), anchor='mm')
    out.save(a.out, optimize=True)
    print('wrote', a.out, out.size)


if __name__ == '__main__':
    main()
