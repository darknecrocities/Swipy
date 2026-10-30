#!/usr/bin/env python3
"""Kinetic Transitions, Swiss Grid & Hardware Frame Engine for 1080p Landscape.

Directorial Palette: Pure White (#FFFFFF) with Pitch Black (#0A0A0C) Accents.
Provides:
- Mathematical easing curves: snap cubic-bezier(.7,0,.2,1) and quintic smoothstep.
- Architectural Swiss 12-column hairline drafting grid and crosshairs.
- Precision HUD drafting brackets, coordinate reticles, and inverted black pill badges.
- Landscape photorealistic MacBook Pro hardware frame with notch & drop shadow.
- 1080p transition filters: slice curtain zebra blinds, symmetrical mirror split, circular iris wipe.

Complies strictly with SkillBuilder cognitive limits (<500 lines).
"""

import math
import numpy as np
from PIL import Image, ImageDraw, ImageFont

W, H = 1920, 1080

FONT_HEADING = "/System/Library/Fonts/Supplemental/Arial Black.ttf"
FONT_SANS = "/System/Library/Fonts/HelveticaNeue.ttc"
FONT_MONO = "/System/Library/Fonts/Monaco.ttf"


def ease_snap(t: float) -> float:
    """Cubic-bezier(0.7, 0.0, 0.2, 1.0) snap easing curve for Swiss typography."""
    t = max(0.0, min(1.0, t))
    return 3 * (1 - t) ** 2 * t * 0.0 + 3 * (1 - t) * t ** 2 * 1.0 + t ** 3


def ease_smooth(t: float) -> float:
    """Quintic smoothstep: 6t^5 - 15t^4 + 10t^3."""
    t = max(0.0, min(1.0, t))
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)


def draw_swiss_background(draw: ImageDraw.ImageDraw, frame_idx: int):
    """Draw pure studio white canvas with subtle Swiss architectural grid and telemetry."""
    # Pure Studio White
    draw.rectangle([0, 0, W, H], fill=(255, 255, 255))

    # Architectural Hairline vertical grid columns (every 120px)
    for x in range(120, W, 120):
        draw.line([(x, 0), (x, H)], fill=(242, 242, 246), width=1)

    # Architectural Hairline horizontal grid rows (every 90px)
    for y in range(90, H, 90):
        draw.line([(0, y), (W, y)], fill=(242, 242, 246), width=1)

    # Precision drafting crosshair ticks at select intersections
    for cx in (240, 480, 720, 960, 1200, 1440, 1680):
        for cy in (180, 360, 540, 720, 900):
            draw.line([(cx - 8, cy), (cx + 8, cy)], fill=(212, 212, 222), width=1)
            draw.line([(cx, cy - 8), (cx, cy + 8)], fill=(212, 212, 222), width=1)

    # Top Status Telemetry Header
    font_mono = ImageFont.truetype(FONT_MONO, 18)
    sec = frame_idx / 30.0
    timecode = f"00:{int(sec):02d}:{int((sec % 1) * 30):02d}"
    draw.text((64, 38), "[SWIPY // CINEMATIC PRODUCT SHOWCASE]", font=font_mono, fill=(100, 100, 112))
    draw.text((W - 460, 38), f"30 FPS • 120 BPM • 1080P WIDESCREEN • {timecode}", font=font_mono, fill=(140, 140, 150))
    draw.line([(64, 68), (W - 64, 68)], fill=(230, 230, 236), width=1)


def draw_hud_brackets(draw: ImageDraw.ImageDraw, box, color=(12, 12, 14), tick_len=24, width=3):
    """Precision HUD drafting brackets [ TARGET ] with center lock tick."""
    x0, y0, x1, y1 = box
    draw.line([(x0, y0 + tick_len), (x0, y0), (x0 + tick_len, y0)], fill=color, width=width)
    draw.line([(x1 - tick_len, y0), (x1, y0), (x1, y0 + tick_len)], fill=color, width=width)
    draw.line([(x0, y1 - tick_len), (x0, y1), (x0 + tick_len, y1)], fill=color, width=width)
    draw.line([(x1 - tick_len, y1), (x1, y1), (x1 - tick_len, y1)], fill=color, width=width)
    mid_x = (x0 + x1) // 2
    draw.line([(mid_x - 12, y0 - 6), (mid_x + 12, y0 - 6)], fill=color, width=width)


def draw_reticle(draw: ImageDraw.ImageDraw, cx: int, cy: int, radius: int = 40, pulsing: float = 1.0, color=(12, 12, 14)):
    """Draw circular target reticle with crosshairs and lock-on center dot."""
    r = int(radius * pulsing)
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=color, width=2)
    draw.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=color)
    draw.line([(cx - r - 16, cy), (cx + r + 16, cy)], fill=color, width=1)
    draw.line([(cx, cy - r - 16), (cx, cy + r + 16)], fill=color, width=1)


def draw_pill_badge(draw: ImageDraw.ImageDraw, text: str, cx: int, cy: int, font,
                    bg_color=(12, 12, 14), text_color=(255, 255, 255), pad_x=24, pad_y=10):
    """Render a solid rounded pill badge with centered typography."""
    bbox = draw.textbbox((cx, cy), text, font=font, anchor="mm")
    x0 = bbox[0] - pad_x
    y0 = bbox[1] - pad_y
    x1 = bbox[2] + pad_x
    y1 = bbox[3] + pad_y
    radius = (y1 - y0) // 2
    draw.rounded_rectangle([x0, y0, x1, y1], radius=radius, fill=bg_color)
    draw.text((cx, cy), text, font=font, fill=text_color, anchor="mm")
    return [x0, y0, x1, y1]


def draw_macbook_bezel(canvas_img: Image.Image, screen_content: Image.Image, box):
    """Render photorealistic 16:10 MacBook Pro aluminum bezel with notch and drop shadow."""
    draw = ImageDraw.Draw(canvas_img)
    x0, y0, x1, y1 = box
    w = x1 - x0
    h = y1 - y0

    # 1. Soft Ambient Elevation Shadow beneath MacBook chassis
    shadow_pad = 28
    draw.rounded_rectangle(
        [x0 - 8, y0 + 14, x1 + 8, y1 + shadow_pad],
        radius=20,
        fill=(226, 226, 234)
    )

    # 2. Outer Aluminum Chassis (Space Gray/Silver)
    draw.rounded_rectangle(
        [x0, y0, x1, y1],
        radius=18,
        fill=(26, 26, 30),
        outline=(60, 60, 66),
        width=2
    )

    # 3. Inner Screen Area (16:10 aspect ratio)
    screen_pad_x = 12
    screen_pad_top = 14
    screen_pad_bottom = 20
    sx0 = x0 + screen_pad_x
    sy0 = y0 + screen_pad_top
    sx1 = x1 - screen_pad_x
    sy1 = y1 - screen_pad_bottom
    sw = sx1 - sx0
    sh = sy1 - sy0

    # Resize screen content and paste
    resized_screen = screen_content.resize((sw, sh), Image.Resampling.BILINEAR)
    canvas_img.paste(resized_screen, (sx0, sy0))

    # 4. Top Camera Notch Cutout
    notch_w = int(w * 0.16)
    notch_h = 14
    nx0 = x0 + (w - notch_w) // 2
    nx1 = nx0 + notch_w
    ny0 = sy0
    ny1 = sy0 + notch_h
    draw.rounded_rectangle([nx0, ny0 - 4, nx1, ny1], radius=6, fill=(26, 26, 30))
    # Camera lens dot
    draw.ellipse([(nx0 + nx1) // 2 - 2, ny0 + 4, (nx0 + nx1) // 2 + 2, ny0 + 8], fill=(68, 68, 80))

    # 5. Bottom Aluminum Keyboard Lip with Display Groove
    base_h = 16
    bx0 = x0 - int(w * 0.03)
    bx1 = x1 + int(w * 0.03)
    by0 = y1 - 4
    by1 = by0 + base_h
    draw.rounded_rectangle([bx0, by0, bx1, by1], radius=8, fill=(210, 212, 218), outline=(180, 182, 190), width=1)

    # Center finger recess notch
    notch_base_w = int(w * 0.14)
    nbx0 = x0 + (w - notch_base_w) // 2
    nbx1 = nbx0 + notch_base_w
    draw.rounded_rectangle([nbx0, by0, nbx1, by0 + 5], radius=3, fill=(168, 170, 178))


def apply_slice_curtain(current_img: Image.Image, next_img: Image.Image, progress: float, num_slices=12) -> Image.Image:
    """Slice curtain transition: alternating horizontal zebra blinds sliding apart."""
    out = current_img.copy()
    slice_h = H // num_slices
    p = ease_snap(progress)

    for i in range(num_slices):
        y0 = i * slice_h
        y1 = (i + 1) * slice_h if i < num_slices - 1 else H
        strip = next_img.crop((0, y0, W, y1))

        # Even slices slide in from left, odd slices slide in from right
        if i % 2 == 0:
            offset_x = int((1.0 - p) * -W)
        else:
            offset_x = int((1.0 - p) * W)

        out.paste(strip, (offset_x, y0))

    return out


def apply_symmetrical_split(current_img: Image.Image, next_img: Image.Image, progress: float) -> Image.Image:
    """Symmetrical horizontal split: left and right halves part from center."""
    out = Image.new("RGB", (W, H), (255, 255, 255))
    p = ease_snap(progress)
    half_w = W // 2

    # Draw next image in center
    out.paste(next_img, (0, 0))

    # Slide current halves outward
    offset = int(p * half_w)
    left_half = current_img.crop((0, 0, half_w, H))
    right_half = current_img.crop((half_w, 0, W, H))

    if offset < half_w:
        out.paste(left_half, (-offset, 0))
        out.paste(right_half, (half_w + offset, 0))

    # Center divider hairline
    draw = ImageDraw.Draw(out)
    draw.line([(half_w - offset, 0), (half_w - offset, H)], fill=(220, 220, 228), width=2)
    draw.line([(half_w + offset, 0), (half_w + offset, H)], fill=(220, 220, 228), width=2)

    return out


def apply_iris_wipe(current_img: Image.Image, next_img: Image.Image, progress: float) -> Image.Image:
    """Expanding circular iris wipe from center with feathered edge."""
    p = ease_snap(progress)
    max_radius = math.hypot(W // 2, H // 2) * 1.05
    radius = int(p * max_radius)

    mask = Image.new("L", (W, H), 0)
    m_draw = ImageDraw.Draw(mask)
    cx, cy = W // 2, H // 2
    m_draw.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=255)

    return Image.composite(next_img, current_img, mask)
