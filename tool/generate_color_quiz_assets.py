"""Generate PNG previews for the color-type quiz (not body-type quiz)."""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "color_quiz"
SIZE = (200, 200)
BG = (255, 248, 251, 255)
FRAME = (26, 26, 26, 255)


def _base() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", SIZE, BG)
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle((8, 8, SIZE[0] - 8, SIZE[1] - 8), 14, outline=FRAME, width=2)
    return img, draw


def _save(stem: str, img: Image.Image) -> None:
    path = OUT / f"{stem}.png"
    img.convert("RGB").save(path, format="PNG", optimize=True)
    print(path.name)


def eye(stem: str, iris: tuple[int, int, int], ring: tuple[int, int, int]) -> None:
    img, draw = _base()
    cx, cy = 100, 108
    draw.ellipse((cx - 52, cy - 34, cx + 52, cy + 34), fill=(248, 240, 235, 255))
    draw.ellipse((cx - 38, cy - 38, cx + 38, cy + 38), fill=(*iris, 255))
    draw.ellipse((cx - 22, cy - 22, cx + 22, cy + 22), fill=(*ring, 255))
    draw.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), fill=(20, 20, 24, 255))
    draw.ellipse((cx - 4, cy - 12, cx + 2, cy - 4), fill=(255, 255, 255, 180))
    _save(stem, img)


def hair(stem: str, main: tuple[int, int, int], highlight: tuple[int, int, int]) -> None:
    img, draw = _base()
    draw.ellipse((40, 28, 160, 150), fill=(*main, 255))
    for x in range(50, 150, 14):
        draw.line((x, 40, x + 6, 170), fill=(*highlight, 255), width=8)
    draw.arc((55, 20, 145, 120), 200, 340, fill=(*highlight, 255), width=10)
    _save(stem, img)


def undertone(stem: str, swatches: list[tuple[int, int, int]]) -> None:
    img, draw = _base()
    n = len(swatches)
    w = (SIZE[0] - 40) // n
    for i, c in enumerate(swatches):
        x0 = 20 + i * w
        draw.rounded_rectangle((x0 + 4, 50, x0 + w - 4, 150), 12, fill=(*c, 255))
    _save(stem, img)


def contrast(
    stem: str,
    bg: tuple[int, int, int],
    hair_c: tuple[int, int, int],
    skin: tuple[int, int, int],
) -> None:
    img, draw = _base()
    draw.rectangle((0, 0, SIZE[0], SIZE[1]), fill=(*bg, 255))
    draw.ellipse((55, 35, 145, 165), fill=(*skin, 255))
    draw.ellipse((55, 20, 145, 95), fill=(*hair_c, 255))
    draw.ellipse((78, 88, 92, 92), fill=(30, 30, 35, 255))
    draw.ellipse((108, 88, 122, 92), fill=(30, 30, 35, 255))
    _save(stem, img)


def depth(stem: str, tone: tuple[int, int, int]) -> None:
    img, draw = _base()
    draw.rounded_rectangle((30, 45, 170, 165), 24, fill=(*tone, 255))
    draw.ellipse((70, 95, 78, 103), fill=(40, 30, 28, 120))
    draw.ellipse((122, 95, 130, 103), fill=(40, 30, 28, 120))
    draw.arc((85, 115, 115, 135), 20, 160, fill=(40, 30, 28, 90), width=4)
    _save(stem, img)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)

    eye("eye_light_blue", (120, 175, 220), (90, 140, 190))
    eye("eye_green_hazel", (110, 150, 115), (85, 120, 90))
    eye("eye_warm_brown", (150, 100, 55), (120, 75, 40))
    eye("eye_dark_brown", (55, 38, 28), (35, 24, 18))

    hair("hair_light_blonde", (235, 215, 175), (255, 245, 220))
    hair("hair_golden", (210, 145, 55), (240, 185, 90))
    hair("hair_cool_brown", (105, 82, 68), (140, 115, 98))
    hair("hair_dark", (42, 32, 28), (68, 52, 45))

    undertone("undertone_warm", [(232, 184, 138), (240, 205, 165), (210, 155, 105)])
    undertone("undertone_cool", [(232, 196, 212), (196, 220, 240), (225, 210, 235)])
    undertone("undertone_neutral", [(210, 190, 175), (225, 210, 198), (185, 165, 150)])

    contrast("contrast_low", (245, 240, 235), (210, 200, 190), (228, 218, 208))
    contrast("contrast_medium", (250, 248, 245), (120, 85, 55), (215, 185, 160))
    contrast("contrast_high", (255, 255, 255), (25, 20, 18), (235, 210, 185))

    depth("depth_light", (245, 225, 210))
    depth("depth_medium", (195, 150, 120))
    depth("depth_deep", (110, 72, 52))


if __name__ == "__main__":
    main()
