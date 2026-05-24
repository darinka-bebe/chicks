"""Export body-type PNGs from the 5-card grid reference (_source_grid.png)."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "body_types" / "_source_grid.png"
OUT = ROOT / "assets" / "body_types"

CANVAS = (320, 340)
BG_RGBA = (255, 245, 249, 255)
TARGET_BOX = (272, 220)  # max figure slot inside canvas
FOOT_BASELINE_Y = 302
SIDE_PAD = 24

CARD_BOXES: dict[str, tuple[int, int, int, int]] = {
    "hourglass": (28, 40, 324, 328),
    "pear": (352, 40, 648, 328),
    "rectangle": (676, 40, 996, 328),
    "inverted_triangle": (72, 358, 428, 642),
    "apple": (468, 358, 824, 642),
}

ILLUSTRATION_HEIGHT_RATIO = 0.62


def _is_figure_pixel(r: int, g: int, b: int, a: int) -> bool:
    """Silhouette outline + body fill only — skip card bg and decorative shapes."""
    if a < 20:
        return False
    if r > 250 and g > 238 and b > 244:
        return False
    if r > 95 and r < 235 and abs(r - g) < 18 and abs(g - b) < 18:
        return False
    if r < 40 and g < 40 and b < 40:
        return True
    if r > 130 and g > 55 and b > 75 and r > g + 8 and r < 230:
        return True
    return False


def _trim_figure(img: Image.Image, pad: int = 6) -> Image.Image:
    px = img.load()
    w, h = img.size
    minx, miny, maxx, maxy = w, h, 0, 0
    for y in range(h):
        for x in range(w):
            if _is_figure_pixel(*px[x, y]):
                minx, miny = min(minx, x), min(miny, y)
                maxx, maxy = max(maxx, x), max(maxy, y)
    if maxx <= minx:
        return img
    return img.crop(
        (
            max(0, minx - pad),
            max(0, miny - pad),
            min(w, maxx + pad),
            min(h, maxy + pad),
        )
    )


def _illustration_zone(card: Image.Image) -> Image.Image:
    cw, ch = card.size
    top = int(ch * ILLUSTRATION_HEIGHT_RATIO)
    return _trim_figure(card.crop((0, 0, cw, top)))


def _normalize_canvas(tight: Image.Image) -> Image.Image:
    max_w, max_h = TARGET_BOX
    scale = min(max_w / tight.width, max_h / tight.height)
    nw = max(1, int(tight.width * scale))
    nh = max(1, int(tight.height * scale))
    scaled = tight.resize((nw, nh), Image.Resampling.LANCZOS)

    # Horizontal center by figure mass, not image bounds.
    px = scaled.load()
    sum_x = 0.0
    count = 0
    for y in range(nh):
        for x in range(nw):
            if _is_figure_pixel(*px[x, y]):
                sum_x += x
                count += 1
    centroid_x = (sum_x / count) if count else nw / 2

    canvas = Image.new("RGBA", CANVAS, BG_RGBA)
    x = int(CANVAS[0] / 2 - centroid_x)
    x = max(SIDE_PAD // 2, min(x, CANVAS[0] - nw - SIDE_PAD // 2))
    y = FOOT_BASELINE_Y - nh
    canvas.paste(scaled, (x, y), scaled)
    return canvas


def export_all() -> None:
    im = Image.open(SRC).convert("RGBA")
    for name, box in CARD_BOXES.items():
        card = im.crop(box)
        ill = _illustration_zone(card)
        out = _normalize_canvas(ill)
        out.save(OUT / f"{name}.png")
        print(f"exported {name}.png figure={ill.size[0]}x{ill.size[1]}")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    if not SRC.exists():
        raise SystemExit(f"Missing reference grid: {SRC}")
    export_all()


if __name__ == "__main__":
    main()
