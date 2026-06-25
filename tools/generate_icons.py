#!/usr/bin/env python3
"""Generate app icons for まもる計算."""
from __future__ import annotations

import json
import shutil
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
NAVY = (26, 58, 92)
BLUE = (37, 99, 235)
WHITE = (255, 255, 255)


def draw_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), NAVY + (255,))
    draw = ImageDraw.Draw(img)
    pad = size // 6
    draw.rounded_rectangle(
        [pad, pad, size - pad, size - pad],
        radius=size // 8,
        fill=BLUE + (255,),
    )

    bar_w = size // 10
    gap = size // 16
    base_y = size - pad - size // 5
    heights = [size // 6, size // 4, size // 3]
    start_x = size // 2 - (bar_w * 3 + gap * 2) // 2
    for i, h in enumerate(heights):
        x = start_x + i * (bar_w + gap)
        draw.rounded_rectangle(
            [x, base_y - h, x + bar_w, base_y],
            radius=bar_w // 4,
            fill=WHITE + (255,),
        )

    shield_w = size // 5
    cx = size // 2
    top = pad + size // 10
    draw.polygon(
        [
            (cx, top),
            (cx + shield_w, top + shield_w // 2),
            (cx + shield_w // 2, top + shield_w),
            (cx - shield_w // 2, top + shield_w),
            (cx - shield_w, top + shield_w // 2),
        ],
        fill=WHITE + (230,),
    )
    return img


def save_png(size: int, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    draw_icon(size).save(path, format="PNG")


def main() -> None:
    android_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, size in android_sizes.items():
        save_png(
            size,
            ROOT / "android/app/src/main/res" / folder / "ic_launcher.png",
        )

    web_sizes = [192, 512]
    for size in web_sizes:
        save_png(size, ROOT / "web/icons" / f"Icon-{size}.png")
        save_png(size, ROOT / "web/icons" / f"Icon-maskable-{size}.png")

    ios_dir = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    ios_icons = [
        (20, 1), (20, 2), (20, 3),
        (29, 1), (29, 2), (29, 3),
        (40, 1), (40, 2), (40, 3),
        (60, 2), (60, 3),
        (76, 1), (76, 2),
        (83.5, 2),
        (1024, 1),
    ]
    contents_images: list[dict] = []
    for base, scale in ios_icons:
        px = int(base * scale)
        filename = f"Icon-{base}x{base}@{scale}x.png"
        save_png(px, ios_dir / filename)
        contents_images.append(
            {
                "size": f"{base}x{base}",
                "idiom": "iphone" if base != 83.5 and base != 76 else "ipad",
                "filename": filename,
                "scale": f"{scale}x",
            }
        )

    contents = {
        "images": contents_images,
        "info": {"author": "xcode", "version": 1},
    }
    with open(ios_dir / "Contents.json", "w", encoding="utf-8") as f:
        json.dump(contents, f, indent=2)

    mac_dir = ROOT / "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    for name, size in [
        ("app_icon_16.png", 16),
        ("app_icon_32.png", 32),
        ("app_icon_64.png", 64),
        ("app_icon_128.png", 128),
        ("app_icon_256.png", 256),
        ("app_icon_512.png", 512),
        ("app_icon_1024.png", 1024),
    ]:
        save_png(size, mac_dir / name)

    print("Icons generated successfully.")


if __name__ == "__main__":
    main()
