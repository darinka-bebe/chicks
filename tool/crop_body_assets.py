"""Crop body-type illustration tiles from reference screenshot."""
from pathlib import Path

from PIL import Image

SRC = Path(
    r"C:\Users\Пользователь\.cursor\projects\c-chicks\assets"
    r"\c__Users______________AppData_Roaming_Cursor_User_workspaceStorage_"
    r"3c6416b586f809085696aba4f25a3769_images_image-d41d936c-04bb-4a98-a0f3-834d04743366.png"
)
OUT = Path(__file__).resolve().parent.parent / "assets" / "body_types"

# left, top, right, bottom — tuned for 818×976 reference
BOXES = {
    "pear": (42, 248, 168, 382),
    "rectangle": (42, 398, 168, 532),
    "apple": (42, 548, 168, 682),
    "hourglass": (42, 698, 168, 832),
    "inverted_triangle": (42, 848, 168, 962),
}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    im = Image.open(SRC).convert("RGBA")
    for name, box in BOXES.items():
        crop = im.crop(box)
        out = crop.resize((crop.width * 2, crop.height * 2), Image.Resampling.LANCZOS)
        out.save(OUT / f"{name}.png")
        print(f"wrote {name}.png {out.size}")


if __name__ == "__main__":
    main()
