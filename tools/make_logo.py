"""Renders the Bloxo neon logo and app icons as PNG files.

Run from the project folder:  python3 tools/make_logo.py
Needs Pillow (pip install pillow). Outputs:
  icon.png                              512x512 app icon (Godot project icon)
  assets/images/logo.png                1200x360 transparent logo (splash, store)
  assets/images/icon_foreground.png     432x432 Android adaptive icon foreground
  assets/images/icon_background.png     432x432 Android adaptive icon background
  assets/images/store_icon.png          512x512 Google Play store icon
  assets/images/feature_graphic.png     1024x500 Google Play feature graphic

The letters match ui/neon_logo.gd so the in-game logo and the images agree.
"""
import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.join(os.path.dirname(__file__), "..")
IMG = os.path.join(ROOT, "assets", "images")

LETTERS = {
    "B": ["XXXX.", "X...X", "XXXX.", "X...X", "XXXX."],
    "L": ["X....", "X....", "X....", "X....", "XXXXX"],
    "O": [".XXX.", "X...X", "X...X", "X...X", ".XXX."],
    "X": ["X...X", ".X.X.", "..X..", ".X.X.", "X...X"],
}
WORD = "BLOXO"
# Same colors / order as Palette.piece_colors + NeonLogo.LETTER_COLORS
COLORS = ["#FF2E88", "#00F0FF", "#FFE600", "#39FF88", "#B026FF"]
BG_TOP = (21, 10, 51)
BG_BOTTOM = (4, 2, 12)


def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def mix(c, other, t):
    return tuple(int(a + (b - a) * t) for a, b in zip(c, other))


def word_cells(word):
    """[(col, row, color_hex)] for a word, 5x5 letters with 1 column gap."""
    cells, col = [], 0
    for i, ch in enumerate(word):
        for y, row in enumerate(LETTERS[ch]):
            for x, v in enumerate(row):
                if v == "X":
                    cells.append((col + x, y, COLORS[i % len(COLORS)]))
        col += 6
    return cells, col - 1


def draw_neon_cells(size, cells, cell, origin, glow_strength=1.0):
    """Returns an RGBA image with glowing neon blocks."""
    w, h = size
    glow = Image.new("RGBA", size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    body = Image.new("RGBA", size, (0, 0, 0, 0))
    bd = ImageDraw.Draw(body)
    gap = cell * 0.12
    radius = cell * 0.2
    edge = max(2, int(cell * 0.1))
    for cx, cy, hx in cells:
        rgb = hex_rgb(hx)
        x0 = origin[0] + cx * cell + gap / 2
        y0 = origin[1] + cy * cell + gap / 2
        box = [x0, y0, x0 + cell - gap, y0 + cell - gap]
        gd.rounded_rectangle(box, radius=radius, fill=rgb + (255,))
        bd.rounded_rectangle(box, radius=radius, fill=mix(rgb, (0, 0, 0), 0.5) + (235,),
                             outline=mix(rgb, (255, 255, 255), 0.15) + (255,), width=edge)
        sx0 = x0 + (cell - gap) * 0.22
        sy0 = y0 + (cell - gap) * 0.2
        bd.rounded_rectangle([sx0, sy0, sx0 + (cell - gap) * 0.4, sy0 + (cell - gap) * 0.1],
                             radius=cell * 0.05, fill=(255, 255, 255, 120))
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    for blur, alpha in ((cell * 0.9, 0.55), (cell * 0.35, 0.8)):
        g = glow.filter(ImageFilter.GaussianBlur(blur))
        a = g.getchannel("A").point(lambda v: int(v * alpha * glow_strength))
        g.putalpha(a)
        out = Image.alpha_composite(out, g)
    return Image.alpha_composite(out, body)


def gradient(size, top=BG_TOP, bottom=BG_BOTTOM):
    w, h = size
    img = Image.new("RGBA", size)
    d = ImageDraw.Draw(img)
    for y in range(h):
        d.line([(0, y), (w, y)], fill=mix(top, bottom, y / max(1, h - 1)) + (255,))
    return img


def rounded_mask(size, radius):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size[0] - 1, size[1] - 1], radius=radius, fill=255)
    return m


def logo(width=1200, height=360):
    cells, cols = word_cells(WORD)
    cell = min((width * 0.86) / cols, (height * 0.7) / 5)
    origin = ((width - cols * cell) / 2, (height - 5 * cell) / 2)
    return draw_neon_cells((width, height), cells, cell, origin)


def letter_icon(size, letter="B", color=COLORS[0], fill_ratio=0.62):
    cells = [(x, y, color) for y, row in enumerate(LETTERS[letter])
             for x, v in enumerate(row) if v == "X"]
    cell = size * fill_ratio / 5
    origin = ((size - 5 * cell) / 2 + cell * 0.1, (size - 5 * cell) / 2)
    return draw_neon_cells((size, size), cells, cell, origin)


def app_icon(size=512, rounded=True):
    bg = gradient((size, size))
    img = Image.alpha_composite(bg, letter_icon(size))
    if rounded:
        img.putalpha(rounded_mask((size, size), int(size * 0.22)))
    return img


def save(img, *parts):
    path = os.path.join(ROOT, *parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print("wrote", os.path.normpath(path))


if __name__ == "__main__":
    save(app_icon(512), "icon.png")
    save(app_icon(512, rounded=False), "assets", "images", "store_icon.png")
    save(logo(), "assets", "images", "logo.png")
    # Android adaptive icon: foreground must sit inside the middle ~66%.
    save(letter_icon(432, fill_ratio=0.42), "assets", "images", "icon_foreground.png")
    save(gradient((432, 432)), "assets", "images", "icon_background.png")
    feature = gradient((1024, 500))
    feature = Image.alpha_composite(feature, logo(1024, 500))
    save(feature, "assets", "images", "feature_graphic.png")
