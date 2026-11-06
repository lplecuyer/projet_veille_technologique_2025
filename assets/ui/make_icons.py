"""Génère les icônes du HUD (classes et actions) en PNG 256x256 à fond transparent."""
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

S = 1024  # dessin en haute résolution puis réduction pour l'antialiasing
OUT = 256
C = S // 2

GOLD = (201, 162, 74, 255)
GOLD_DARK = (122, 92, 36, 255)
INK = (22, 17, 14, 255)


def hgradient(size, left, right):
    w, h = size
    img = Image.new("RGBA", size)
    px = img.load()
    for x in range(w):
        t = x / (w - 1)
        col = tuple(int(left[i] + (right[i] - left[i]) * t) for i in range(4))
        for y in range(h):
            px[x, y] = col
    return img


def vgradient(size, top, bottom):
    return hgradient(size[::-1], top, bottom).rotate(-90, expand=True).transpose(Image.FLIP_LEFT_RIGHT)


def outline(mask, width):
    grown = mask.filter(ImageFilter.MaxFilter(width * 2 + 1))
    return ImageChops.subtract(grown, mask)


def fill_mask(canvas, mask, fill):
    layer = fill if isinstance(fill, Image.Image) else Image.new("RGBA", canvas.size, fill)
    canvas.paste(layer, (0, 0), mask)


def medallion(inner_top, inner_bottom):
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse((24, 24, S - 24, S - 24), fill=INK)
    d.ellipse((44, 44, S - 44, S - 44), fill=GOLD_DARK)
    d.ellipse((56, 56, S - 56, S - 72), fill=GOLD)
    inner = Image.new("L", (S, S), 0)
    ImageDraw.Draw(inner).ellipse((96, 96, S - 96, S - 96), fill=255)
    d.ellipse((88, 88, S - 88, S - 88), fill=INK)
    fill_mask(img, inner, vgradient((S, S), inner_top, inner_bottom))
    return img, inner


def knight():
    img, inner = medallion((70, 88, 120, 255), (28, 34, 52, 255))
    fig = Image.new("RGBA", (S, S), (0, 0, 0, 0))

    helm = Image.new("L", (S, S), 0)
    h = ImageDraw.Draw(helm)
    h.ellipse((318, 210, 706, 560), fill=255)
    h.rectangle((318, 385, 706, 740), fill=255)
    h.polygon([(318, 740), (706, 740), (660, 820), (364, 820)], fill=255)

    fill_mask(fig, outline(helm, 18), INK)
    fill_mask(fig, helm, hgradient((S, S), (226, 232, 238, 255), (112, 124, 138, 255)))
    # On ne garde que la partie du dégradé sous le casque
    shade = Image.new("L", (S, S), 0)
    ImageDraw.Draw(shade).rectangle((512, 0, S, S), fill=70)
    fill_mask(fig, ImageChops.multiply(shade, helm), (20, 26, 34, 255))

    d = ImageDraw.Draw(fig)
    # Arête centrale
    d.polygon([(500, 215), (524, 215), (530, 470), (494, 470)], fill=(244, 247, 250, 255))
    # Fente de la visière
    d.rounded_rectangle((350, 470, 674, 520), radius=14, fill=INK)
    d.rectangle((494, 462, 530, 760), fill=(150, 160, 172, 255))
    d.rectangle((494, 462, 530, 760), outline=INK, width=8)
    # Trous de respiration
    for row in range(3):
        for col in range(3):
            x, y = 575 + col * 32, 600 + row * 40
            d.ellipse((x, y, x + 16, y + 16), fill=INK)
    # Bande dorée en bas
    d.polygon([(326, 735), (698, 735), (680, 772), (344, 772)], fill=GOLD)

    img.paste(fig, (0, 0), ImageChops.multiply(fig.getchannel("A"), inner))
    return img


def dagger_layer(angle):
    lay = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    m = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(m)
    d.polygon([(512, 120), (548, 230), (540, 640), (484, 640), (476, 230)], fill=255)
    fill_mask(lay, outline(m, 14), INK)
    fill_mask(lay, m, hgradient((S, S), (238, 240, 244, 255), (130, 138, 150, 255)))
    d2 = ImageDraw.Draw(lay)
    d2.line((512, 150, 512, 620), fill=(255, 255, 255, 200), width=6)
    d2.rounded_rectangle((420, 636, 604, 676), radius=12, fill=GOLD, outline=INK, width=10)
    d2.rounded_rectangle((490, 676, 534, 820), radius=10, fill=(92, 52, 34, 255), outline=INK, width=10)
    d2.ellipse((480, 812, 544, 876), fill=GOLD, outline=INK, width=10)
    return lay.rotate(angle, resample=Image.BICUBIC, center=(C, C + 120))


def rogue():
    img, inner = medallion((70, 50, 92, 255), (24, 18, 34, 255))
    fig = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    fig.alpha_composite(dagger_layer(52))
    fig.alpha_composite(dagger_layer(-52))

    hood = Image.new("L", (S, S), 0)
    h = ImageDraw.Draw(hood)
    h.ellipse((336, 290, 688, 750), fill=255)
    h.polygon([(512, 200), (650, 390), (374, 390)], fill=255)
    h.polygon([(336, 560), (688, 560), (730, 900), (294, 900)], fill=255)

    fill_mask(fig, outline(hood, 18), INK)
    fill_mask(fig, hood, hgradient((S, S), (68, 96, 70, 255), (26, 40, 30, 255)))
    d = ImageDraw.Draw(fig)
    # Pli du capuchon
    d.line((512, 205, 470, 400), fill=(100, 134, 100, 255), width=10)
    # Ouverture du visage
    d.ellipse((392, 410, 632, 700), fill=(10, 8, 12, 255))
    # Yeux lumineux en amande
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    g = ImageDraw.Draw(glow)
    g.polygon([(432, 540), (490, 528), (496, 556), (442, 560)], fill=(255, 214, 90, 255))
    g.polygon([(592, 540), (534, 528), (528, 556), (582, 560)], fill=(255, 214, 90, 255))
    halo = glow.filter(ImageFilter.GaussianBlur(14))
    fig.alpha_composite(halo)
    fig.alpha_composite(glow)
    # Fermoir doré
    d.ellipse((480, 760, 544, 824), fill=GOLD, outline=INK, width=10)

    img.paste(fig, (0, 0), ImageChops.multiply(fig.getchannel("A"), inner))
    return img


# --- Icônes de la barre d'actions (fond transparent, sans médaillon) ---


def framed(mask, fill, rim=None, rim_width=0):
    """Remplit `mask` avec `fill`, un liseré `rim` optionnel et un contour noir."""
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    body = mask
    if rim:
        body = mask.filter(ImageFilter.MaxFilter(rim_width * 2 + 1))
    fill_mask(img, outline(body, 16), INK)
    if rim:
        fill_mask(img, body, rim)
    fill_mask(img, mask, fill)
    return img


def sword():
    m = Image.new("L", (S, S), 0)
    ImageDraw.Draw(m).polygon([(512, 90), (560, 190), (552, 650), (472, 650), (464, 190)], fill=255)
    img = framed(m, hgradient((S, S), (245, 247, 250, 255), (130, 140, 155, 255)))
    d = ImageDraw.Draw(img)
    d.line((512, 130, 512, 630), fill=(255, 255, 255, 220), width=8)
    d.rounded_rectangle((340, 640, 684, 696), radius=20, fill=GOLD, outline=INK, width=14)
    d.rounded_rectangle((482, 696, 542, 870), radius=14, fill=(92, 52, 34, 255), outline=INK, width=14)
    for y in (730, 780, 830):
        d.line((486, y, 538, y - 16), fill=(60, 34, 22, 255), width=8)
    d.ellipse((468, 860, 556, 948), fill=GOLD, outline=INK, width=14)
    return img.rotate(-45, resample=Image.BICUBIC, center=(C, C))


def shield():
    m = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle((250, 150, 774, 520), radius=40, fill=255)
    d.polygon([(250, 480), (774, 480), (720, 690), (512, 890), (304, 690)], fill=255)
    img = framed(m, vgradient((S, S), (70, 100, 160, 255), (30, 44, 80, 255)), rim=GOLD, rim_width=26)
    # Croix dorée, coupée à la forme du bouclier
    cross = Image.new("L", (S, S), 0)
    c = ImageDraw.Draw(cross)
    c.rectangle((482, 150, 542, 900), fill=255)
    c.rectangle((250, 380, 774, 440), fill=255)
    fill_mask(img, ImageChops.multiply(cross, m), GOLD)
    # Reflet sur la moitié gauche
    shine = Image.new("L", (S, S), 0)
    ImageDraw.Draw(shine).polygon([(250, 150), (482, 150), (482, 880), (304, 690), (250, 480)], fill=40)
    fill_mask(img, ImageChops.multiply(shine, m), (255, 255, 255, 255))
    return img


def dash():
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    m = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(m)
    for x in (430, 620):
        d.polygon([(x - 150, 260), (x - 40, 260), (x + 150, 512), (x - 40, 764), (x - 150, 764), (x + 40, 512)], fill=255)
    fill_mask(img, outline(m, 16), INK)
    fill_mask(img, m, hgradient((S, S), (120, 200, 255, 255), (235, 250, 255, 255)))
    # Traînées de vitesse derrière les chevrons
    lines = ImageDraw.Draw(img)
    for y, x0, alpha in ((380, 90, 160), (512, 40, 220), (644, 90, 160)):
        lines.rounded_rectangle((x0, y - 18, 250, y + 18), radius=18, fill=(170, 225, 255, alpha))
    return img


def heart_mask():
    m = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(m)
    d.ellipse((150, 200, 530, 580), fill=255)
    d.ellipse((494, 200, 874, 580), fill=255)
    d.polygon([(168, 470), (856, 470), (512, 880)], fill=255)
    return m


def heart_full():
    m = heart_mask()
    img = framed(m, vgradient((S, S), (235, 70, 60, 255), (140, 20, 28, 255)), rim=GOLD, rim_width=26)
    # Reflet en haut à gauche
    shine = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(shine).ellipse((250, 290, 400, 400), fill=(255, 255, 255, 150))
    img.alpha_composite(shine.filter(ImageFilter.GaussianBlur(10)))
    return img


def heart_empty():
    return framed(heart_mask(), (40, 30, 28, 255), rim=GOLD_DARK, rim_width=26)


ICONS = (
    ("KnightIcon", knight),
    ("RogueIcon", rogue),
    ("AttackIcon", sword),
    ("ParryIcon", shield),
    ("DashIcon", dash),
    ("HeartFull", heart_full),
    ("HeartEmpty", heart_empty),
)


if __name__ == "__main__":
    out_dir = Path(sys.argv[1])
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, fn in ICONS:
        fn().resize((OUT, OUT), Image.LANCZOS).save(out_dir / f"{name}.png")
        print("écrit", out_dir / f"{name}.png")
