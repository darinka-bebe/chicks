"""Generate flat-lay style PNGs for wardrobe mock seed (not body-type quiz)."""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "wardrobe_mock"
SIZE = (480, 480)
BG = (255, 245, 249, 255)


def _canvas() -> Image.Image:
    img = Image.new("RGBA", SIZE, BG)
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle((24, 24, SIZE[0] - 24, SIZE[1] - 24), 28, fill=(255, 252, 254, 255))
    return img, draw


def _shadow(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int]) -> None:
    x0, y0, x1, y1 = box
    draw.ellipse((x0 + 20, y1 - 18, x1 - 20, y1 + 28), fill=(240, 220, 228, 180))


def save(name: str, img: Image.Image) -> None:
    path = OUT / f"{name}.png"
    img.convert("RGB").save(path, format="PNG", optimize=True)
    print(f"wrote {path.name}")


def shirt_white() -> None:
    img, draw = _canvas()
    box = (120, 110, 360, 360)
    _shadow(draw, box)
    draw.rounded_rectangle(box, 36, fill=(248, 248, 252, 255), outline=(220, 220, 228, 255), width=3)
    draw.polygon([(170, 110), (210, 170), (250, 110)], fill=(248, 248, 252, 255))
    draw.polygon([(310, 110), (270, 170), (230, 110)], fill=(248, 248, 252, 255))
    draw.rectangle((228, 110, 252, 200), fill=(235, 235, 242, 255))
    save("01_white_shirt", img)


def jeans_blue() -> None:
    img, draw = _canvas()
    box = (150, 90, 330, 380)
    _shadow(draw, box)
    draw.rounded_rectangle((150, 90, 240, 380), 22, fill=(72, 98, 145, 255))
    draw.rounded_rectangle((240, 90, 330, 380), 22, fill=(58, 82, 128, 255))
    draw.rectangle((228, 200, 252, 280), fill=(90, 118, 168, 255))
    save("02_jeans", img)


def blazer_beige() -> None:
    img, draw = _canvas()
    box = (100, 100, 380, 370)
    _shadow(draw, box)
    draw.rounded_rectangle(box, 40, fill=(210, 188, 158, 255), outline=(180, 158, 130, 255), width=3)
    draw.line((240, 130, 240, 340), fill=(175, 150, 120, 255), width=6)
    draw.ellipse((210, 250, 270, 310), fill=(195, 170, 140, 255))
    save("03_blazer", img)


def sneakers() -> None:
    img, draw = _canvas()
    _shadow(draw, (90, 220, 390, 340))
    draw.rounded_rectangle((90, 250, 230, 330), 28, fill=(248, 248, 252, 255), outline=(230, 230, 238, 255), width=2)
    draw.rounded_rectangle((250, 250, 390, 330), 28, fill=(248, 248, 252, 255), outline=(230, 230, 238, 255), width=2)
    draw.rounded_rectangle((95, 220, 225, 280), 20, fill=(255, 182, 198, 255))
    draw.rounded_rectangle((255, 220, 385, 280), 20, fill=(255, 182, 198, 255))
    save("04_sneakers", img)


def dress_black() -> None:
    img, draw = _canvas()
    box = (140, 80, 340, 390)
    _shadow(draw, box)
    draw.polygon([(240, 80), (310, 150), (340, 390), (140, 390), (170, 150)], fill=(32, 32, 38, 255))
    draw.ellipse((205, 95, 275, 145), fill=(48, 48, 55, 255))
    save("05_dress", img)


def sweater_pink() -> None:
    img, draw = _canvas()
    box = (110, 110, 370, 360)
    _shadow(draw, box)
    draw.rounded_rectangle(box, 44, fill=(232, 198, 210, 255), outline=(210, 175, 188, 255), width=3)
    for y in range(180, 340, 28):
        draw.line((130, y, 350, y), fill=(220, 185, 198, 120), width=2)
    save("06_sweater", img)


def tote_bag() -> None:
    img, draw = _canvas()
    box = (130, 150, 350, 360)
    _shadow(draw, box)
    draw.rounded_rectangle(box, 30, fill=(186, 140, 92, 255), outline=(160, 118, 75, 255), width=3)
    draw.arc((170, 110, 310, 210), 200, 340, fill=(140, 100, 60, 255), width=14)
    save("07_tote", img)


def trench_khaki() -> None:
    img, draw = _canvas()
    box = (90, 90, 390, 390)
    _shadow(draw, box)
    draw.rounded_rectangle(box, 36, fill=(168, 158, 118, 255), outline=(140, 130, 95, 255), width=3)
    draw.rectangle((220, 90, 260, 180), fill=(150, 140, 100, 255))
    draw.line((240, 180, 240, 390), fill=(130, 120, 85, 255), width=5)
    draw.polygon([(90, 200), (130, 240), (90, 280)], fill=(155, 145, 108, 255))
    draw.polygon([(390, 200), (350, 240), (390, 280)], fill=(155, 145, 108, 255))
    save("08_trench", img)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    shirt_white()
    jeans_blue()
    blazer_beige()
    sneakers()
    dress_black()
    sweater_pink()
    tote_bag()
    trench_khaki()


if __name__ == "__main__":
    main()
