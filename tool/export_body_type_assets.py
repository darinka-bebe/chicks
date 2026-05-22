"""Export body-type PNGs: silhouette + pink geometry (vertical design reference)."""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "body_types"

VERTICAL_SRC = Path(
    r"C:\Users\Пользователь\.cursor\projects\c-chicks\assets"
    r"\c__Users______________AppData_Roaming_Cursor_User_workspaceStorage_"
    r"3c6416b586f809085696aba4f25a3769_images_image-d41d936c-04bb-4a98-a0f3-834d04743366.png"
)

CANVAS = (300, 320)
BG_RGBA = (255, 245, 249, 255)

NAMES = ["pear", "rectangle", "apple", "hourglass", "inverted_triangle"]
ICON_X = (32, 198)
ICON_Y0 = 198
ICON_SLOT = 148
ICON_GAP = 11


def _is_near_black(r: int, g: int, b: int, a: int) -> bool:
    return a > 100 and r < 50 and g < 50 and b < 50


def _is_mockup_chrome(r: int, g: int, b: int) -> bool:
    """White card frame, gray shadow, black divider — not the illustration."""
    if r > 252 and g > 252 and b > 252:
        return True
    if r < 50 and g < 50 and b < 50:
        return True
    # Neutral gray vertical stripe / card edge
    if r < 220 and abs(r - g) < 22 and abs(g - b) < 22:
        return True
    return False


def _column_black_ratio(px, iw: int, ih: int, x: int) -> float:
    black = 0
    total = 0
    for y in range(ih):
        r, g, b, a = px[x, y]
        if a < 40:
            continue
        total += 1
        if _is_near_black(r, g, b, a) or _is_mockup_chrome(r, g, b):
            black += 1
    return black / total if total else 0.0


def strip_edge_artifacts(img: Image.Image, scan_cols: int = 45) -> Image.Image:
    px = img.load()
    iw, ih = img.size
    scan = min(scan_cols, iw)

    left = 0
    while left < scan and _column_black_ratio(px, iw, ih, left) > 0.55:
        left += 1

    right = iw - 1
    while right >= iw - scan and right > left and _column_black_ratio(px, iw, ih, right) > 0.55:
        right -= 1

    if right <= left:
        return img
    return img.crop((left, 0, right + 1, ih))


def trim_illustration_only(img: Image.Image, pad: int = 4) -> Image.Image:
    """Keep inner pink panel + silhouette; drop outer white card chrome."""
    img = strip_edge_artifacts(img)
    px = img.load()
    iw, ih = img.size
    minx, miny, maxx, maxy = iw, ih, 0, 0
    for y in range(ih):
        for x in range(iw):
            r, g, b, a = px[x, y]
            if a < 20:
                continue
            if _is_mockup_chrome(r, g, b):
                continue
            minx, miny = min(minx, x), min(miny, y)
            maxx, maxy = max(maxx, x), max(maxy, y)
    if maxx <= minx:
        return img
    return img.crop(
        (
            max(0, minx - pad),
            max(0, miny - pad),
            min(iw, maxx + pad),
            min(ih, maxy + pad),
        )
    )


def normalize_canvas(tight: Image.Image) -> Image.Image:
    target_h = CANVAS[1]
    scale = target_h / tight.height
    scaled_w = max(1, int(tight.width * scale))
    scaled = tight.resize((scaled_w, target_h), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", CANVAS, BG_RGBA)
    canvas.paste(scaled, ((CANVAS[0] - scaled_w) // 2, 0), scaled)
    return strip_edge_artifacts(canvas, scan_cols=32)


def export_all() -> None:
    im = Image.open(VERTICAL_SRC).convert("RGBA")
    for i, name in enumerate(NAMES):
        top = ICON_Y0 + i * (ICON_SLOT + ICON_GAP)
        bottom = top + ICON_SLOT
        tile = im.crop((ICON_X[0], top, ICON_X[1], bottom))
        out = normalize_canvas(trim_illustration_only(tile))
        out.save(OUT / f"{name}.png")
        print(f"exported {name}.png")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    if not VERTICAL_SRC.exists():
        raise SystemExit(f"Missing reference: {VERTICAL_SRC}")
    export_all()


if __name__ == "__main__":
    main()
