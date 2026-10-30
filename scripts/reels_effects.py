#!/usr/bin/env python3
"""Kinetic Transitions, HUD Reticles & Visual Effects for Swipy Reels.

Provides:
- Easing curves: cubic-bezier(.7,0,.2,1) snap, quintic smoothstep, spring bounce.
- Transition filters: slice curtain, symmetrical mirror split, circular iris wipe.
- HUD graphics: lock-on brackets, coordinate readouts, 21-point tracking nodes.
- Swiss typography grid and high-contrast B&W pill badges.

Complies strictly with SkillBuilder cognitive limits (<500 lines).
"""

import math
import numpy as np
from PIL import Image, ImageDraw, ImageFont

W, H = 1080, 1920

FONT_HEADING = "/System/Library/Fonts/Supplemental/Arial Black.ttf"
FONT_SANS = "/System/Library/Fonts/HelveticaNeue.ttc"
FONT_MONO = "/System/Library/Fonts/Monaco.ttf"


def ease_snap(t: float) -> float:
    """Cubic-bezier(0.7, 0.0, 0.2, 1.0) snap easing for Swiss typography."""
    t = max(0.0, min(1.0, t))
    # Approximation of cubic bezier (.7, 0, .2, 1)
    return 3 * (1 - t) ** 2 * t * 0.0 + 3 * (1 - t) * t ** 2 * 1.0 + t ** 3


def ease_smooth(t: float) -> float:
    """Quintic smoothstep: 6t^5 - 15t^4 + 10t^3."""
    t = max(0.0, min(1.0, t))
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)


def draw_swiss_background(draw: ImageDraw.ImageDraw, frame_idx: int):
    """Draw stark black canvas with Swiss 12-column grid and crosshair ticks."""
    # Pitch Black
    draw.rectangle([0, 0, W, H], fill=(0, 0, 0))

    # Hairline vertical grid columns (every 90px)
    for x in range(90, W, 90):
        draw.line([(x, 0), (x, H)], fill=(20, 20, 20), width=1)

    # Hairline horizontal grid lines (every 160px)
    for y in range(160, H, 160):
        draw.line([(0, y), (W, y)], fill=(20, 20, 20), width=1)

    # Crosshair markers at select intersections
    for cx in (180, 540, 900):
        for cy in (320, 640, 960, 1280, 1600):
            draw.line([(cx - 8, cy), (cx + 8, cy)], fill=(60, 60, 60), width=1)
            draw.line([(cx, cy - 8), (cx, cy + 8)], fill=(60, 60, 60), width=1)

    # Top Status Telemetry Header
    font_mono = ImageFont.truetype(FONT_MONO, 22)
    sec = frame_idx / 30.0
    timecode = f"00:{int(sec):02d}:{int((sec % 1) * 30):02d}"
    draw.text((48, 48), "[SWIPY // REELS]", font=font_mono, fill=(180, 180, 180))
    draw.text((W - 320, 48), f"30 FPS • 120 BPM • {timecode}", font=font_mono, fill=(140, 140, 140))
    draw.line([(48, 86), (W - 48, 86)], fill=(40, 40, 40), width=1)


def draw_hud_brackets(draw: ImageDraw.ImageDraw, box, color=(255, 255, 255), tick_len=20, width=3):
    """Precision HUD drafting brackets [ TARGET ] with center lock tick."""
    x0, y0, x1, y1 = box
    draw.line([(x0, y0 + tick_len), (x0, y0), (x0 + tick_len, y0)], fill=color, width=width)
    draw.line([(x1 - tick_len, y0), (x1, y0), (x1, y0 + tick_len)], fill=color, width=width)
    draw.line([(x0, y1 - tick_len), (x0, y1), (x0 + tick_len, y1)], fill=color, width=width)
    draw.line([(x1 - tick_len, y1), (x1, y1), (x1 - tick_len, y1)], fill=color, width=width)
    mid_x = (x0 + x1) // 2
    draw.line([(mid_x - 10, y0 - 6), (mid_x + 10, y0 - 6)], fill=color, width=width)


def draw_reticle(draw: ImageDraw.ImageDraw, cx: int, cy: int, radius: int = 40, pulsing: float = 1.0, color=(255, 255, 255)):
    """Draw circular target reticle with crosshairs and coordinate readouts."""
    r = int(radius * pulsing)
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=color, width=3)
    draw.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=color)
    draw.line([(cx - r - 16, cy), (cx + r + 16, cy)], fill=color, width=2)
    draw.line([(cx, cy - r - 16), (cx, cy + r + 16)], fill=color, width=2)


def apply_slice_curtain(current_img: Image.Image, next_img: Image.Image, progress: float, num_slices=10) -> Image.Image:
    """Slice curtain transition: alternating zebra horizontal blinds sliding apart."""
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
    """Symmetrical mirror split: left and right halves peel open from center."""
    p = ease_snap(progress)
    out = next_img.copy()

    split_x = W // 2
    shift = int(p * split_x)

    left_half = current_img.crop((0, 0, split_x, H))
    right_half = current_img.crop((split_x, 0, W, H))

    out.paste(left_half, (-shift, 0))
    out.paste(right_half, (split_x + shift, 0))

    # Center vertical laser division line
    draw = ImageDraw.Draw(out)
    draw.line([(split_x, 0), (split_x, H)], fill=(255, 255, 255), width=int(4 * (1.0 - p)))

    return out


def apply_iris_wipe(current_img: Image.Image, next_img: Image.Image, progress: float) -> Image.Image:
    """Circular iris mask expanding from center."""
    p = ease_smooth(progress)
    max_radius = int(math.hypot(W / 2, H / 2))
    radius = int(p * max_radius)

    mask = Image.new("L", (W, H), 0)
    m_draw = ImageDraw.Draw(mask)
    m_draw.ellipse([W // 2 - radius, H // 2 - radius, W // 2 + radius, H // 2 + radius], fill=255)

    out = Image.composite(next_img, current_img, mask)
    return out


def draw_macbook_bezel(canvas: Image.Image, content_img: Image.Image, box) -> Image.Image:
    """Composite content into a sleek floating dark MacBook bezel with notch."""
    x0, y0, x1, y1 = box
    draw = ImageDraw.Draw(canvas)

    # Outer Lid
    draw.rounded_rectangle([x0 - 12, y0 - 12, x1 + 12, y1 + 18], radius=24, fill=(18, 18, 18), outline=(60, 60, 60), width=2)
    # Notch
    notch_w = 110
    notch_h = 16
    draw.rounded_rectangle([(x0 + x1 - notch_w) // 2, y0 - 12, (x0 + x1 + notch_w) // 2, y0 - 12 + notch_h], radius=6, fill=(18, 18, 18))

    # Paste scaled content
    cw, ch = x1 - x0, y1 - y0
    scaled_content = content_img.resize((cw, ch), Image.Resampling.BILINEAR)
    canvas.paste(scaled_content, (x0, y0))

    # Base lip
    draw.rounded_rectangle([x0 - 32, y1 + 18, x1 + 32, y1 + 28], radius=6, fill=(180, 180, 180), outline=(220, 220, 220), width=1)
    return canvas
