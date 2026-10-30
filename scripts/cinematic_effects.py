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


def draw_studio_background(draw: ImageDraw.ImageDraw, frame_idx: int):
    """Draw pure studio white canvas with subtle organic ambient lighting (zero telemetry HUDs or tags)."""
    # Pure Studio White
    draw.rectangle([0, 0, W, H], fill=(255, 255, 255))

    # Subtle soft architectural grid (hairline, light tone)
    for x in range(160, W, 160):
        draw.line([(x, 0), (x, H)], fill=(245, 245, 248), width=1)
    for y in range(120, H, 120):
        draw.line([(0, y), (W, y)], fill=(245, 245, 248), width=1)


draw_swiss_background = draw_studio_background


def draw_dynamic_highlight(canvas_img: Image.Image, cx: int, cy: int, radius: int = 140,
                           intensity: float = 0.35, color=(0, 122, 255)):
    """Render an organic radial spotlight illumination highlight across active features."""
    if intensity <= 0.0 or radius <= 2:
        return
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    o_draw = ImageDraw.Draw(overlay)
    alpha_max = int(intensity * 140)

    # Concentric soft feathered rings
    r = int(radius)
    o_draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(*color, max(1, alpha_max // 4)))
    r_mid = int(r * 0.65)
    o_draw.ellipse([cx - r_mid, cy - r_mid, cx + r_mid, cy + r_mid], fill=(*color, max(1, alpha_max // 2)))
    r_core = int(r * 0.35)
    o_draw.ellipse([cx - r_core, cy - r_core, cx + r_core, cy + r_core], fill=(*color, alpha_max))
    canvas_img.paste(overlay, (0, 0), overlay)


def apply_camera_shift(img: Image.Image, scene_frame: int, scene_total_frames: int,
                       zoom_amount: float = 0.032, pan_x_amount: float = 18.0,
                       pan_y_amount: float = 8.0) -> Image.Image:
    """Apply subtle organic camera shift (pan + slow push-in zoom) to keep frames dynamic."""
    p = max(0.0, min(1.0, scene_frame / max(1.0, float(scene_total_frames))))
    zoom = 1.0 + zoom_amount * p
    pan_x = pan_x_amount * math.sin(p * math.pi)
    pan_y = pan_y_amount * math.cos(p * math.pi * 0.5)

    new_w = int(W * zoom)
    new_h = int(H * zoom)
    resized = img.resize((new_w, new_h), Image.Resampling.BILINEAR)

    # Crop centered with pan offset
    cx = (new_w // 2) + int(pan_x)
    cy = (new_h // 2) + int(pan_y)
    crop_x0 = max(0, min(new_w - W, cx - W // 2))
    crop_y0 = max(0, min(new_h - H, cy - H // 2))
    return resized.crop((crop_x0, crop_y0, crop_x0 + W, crop_y0 + H))


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


def draw_vector_check(draw: ImageDraw.ImageDraw, cx: int, cy: int, radius: int = 10,
                      badge_color=(255, 255, 255), check_color=(10, 10, 12), width: int = 2):
    """Render a crisp vector checkmark badge (zero font symbol dependencies)."""
    draw.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=badge_color)
    p0 = (cx - int(radius * 0.45), cy)
    p1 = (cx - int(radius * 0.1), cy + int(radius * 0.35))
    p2 = (cx + int(radius * 0.45), cy - int(radius * 0.35))
    draw.line([p0, p1, p2], fill=check_color, width=width)


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


def draw_specular_sheen(canvas_img: Image.Image, box, progress: float):
    """Render a dynamic 45-degree anamorphic specular light sheen sweeping across box."""
    if not (0.0 <= progress <= 1.0):
        return
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    sheen_w = int(w * 0.28)
    sweep_start = -sheen_w - int(h * 0.5)
    sweep_end = w + int(h * 0.5)
    sweep_x = x0 + int(sweep_start + progress * (sweep_end - sweep_start))

    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    o_draw = ImageDraw.Draw(overlay)

    # 45-degree angled light band with soft feathered borders
    slant = int(h * 0.55)
    poly = [
        (sweep_x, y1),
        (sweep_x + sheen_w, y1),
        (sweep_x + sheen_w + slant, y0),
        (sweep_x + slant, y0)
    ]
    o_draw.polygon(poly, fill=(255, 255, 255, 75))
    # Bright specular core ray
    core_w = sheen_w // 4
    core_poly = [
        (sweep_x + core_w, y1),
        (sweep_x + core_w * 2, y1),
        (sweep_x + core_w * 2 + slant, y0),
        (sweep_x + core_w + slant, y0)
    ]
    o_draw.polygon(core_poly, fill=(255, 255, 255, 140))

    # Mask within the bounding box
    mask = Image.new("L", (W, H), 0)
    m_draw = ImageDraw.Draw(mask)
    m_draw.rounded_rectangle(box, radius=16, fill=255)
    overlay.putalpha(Image.composite(overlay.getchannel("A"), mask, mask))
    canvas_img.paste(overlay, (0, 0), overlay)


def draw_skeletal_hand_21(draw: ImageDraw.ImageDraw, origin_x: int, origin_y: int,
                          scale: float = 1.0, pinch_t: float = 0.0, color=(12, 12, 14),
                          glow_color=(120, 120, 136)):
    """Render authentic Apple Vision 21-joint skeletal biometric hand overlay."""
    # Normalized 21-joint bone layout relative to wrist (0, 0)
    # Pinch interpolation moves thumb tip towards index tip
    idx_tip_target = (-14 * scale, -135 * scale)
    th_tip_x = -70 * scale + pinch_t * (idx_tip_target[0] - (-70 * scale))
    th_tip_y = -85 * scale + pinch_t * (idx_tip_target[1] - (-85 * scale))

    joints = [
        (0, 0),                                # 0: Wrist
        (-30 * scale, -30 * scale),            # 1: Thumb CMC
        (-50 * scale, -55 * scale),            # 2: Thumb MCP
        (-62 * scale, -72 * scale),            # 3: Thumb IP
        (th_tip_x, th_tip_y),                  # 4: Thumb TIP
        (-20 * scale, -68 * scale),            # 5: Index MCP
        (-18 * scale, -95 * scale),            # 6: Index PIP
        (-16 * scale, -118 * scale),           # 7: Index DIP
        (-14 * scale, -138 * scale),           # 8: Index TIP (Pointer)
        (4 * scale, -72 * scale),              # 9: Middle MCP
        (6 * scale, -102 * scale),             # 10: Middle PIP
        (8 * scale, -126 * scale),             # 11: Middle DIP
        (9 * scale, -148 * scale),             # 12: Middle TIP
        (26 * scale, -66 * scale),             # 13: Ring MCP
        (28 * scale, -94 * scale),             # 14: Ring PIP
        (30 * scale, -116 * scale),            # 15: Ring DIP
        (31 * scale, -136 * scale),            # 16: Ring TIP
        (46 * scale, -54 * scale),             # 17: Little MCP
        (52 * scale, -76 * scale),             # 18: Little PIP
        (56 * scale, -95 * scale),             # 19: Little DIP
        (59 * scale, -112 * scale),            # 20: Little TIP
    ]
    pts = [(int(origin_x + jx), int(origin_y + jy)) for jx, jy in joints]

    # Connecting Bone Segments
    bones = [
        (0, 1), (1, 2), (2, 3), (3, 4),        # Thumb chain
        (0, 5), (5, 6), (6, 7), (7, 8),        # Index chain
        (0, 9), (9, 10), (10, 11), (11, 12),   # Middle chain
        (0, 13), (13, 14), (14, 15), (15, 16), # Ring chain
        (0, 17), (17, 18), (18, 19), (19, 20), # Little chain
        (5, 9), (9, 13), (13, 17)              # Palm knuckle arch
    ]
    for b0, b1 in bones:
        draw.line([pts[b0], pts[b1]], fill=glow_color, width=2)

    # Render Joint Spheres & Rings
    for idx, (px, py) in enumerate(pts):
        r = 5 if idx in (4, 8, 12, 16, 20) else 3
        draw.ellipse([px - r - 2, py - r - 2, px + r + 2, py + r + 2], outline=glow_color, width=1)
        draw.ellipse([px - r, py - r, px + r, py + r], fill=color)

    # Active Pointer Tip Glowing Core
    ipt_x, ipt_y = pts[8]
    draw.ellipse([ipt_x - 9, ipt_y - 9, ipt_x + 9, ipt_y + 9], outline=color, width=2)
    return pts[8]  # Returns index tip coordinates


def draw_shockwave_ring(draw: ImageDraw.ImageDraw, cx: int, cy: int, progress: float,
                        max_radius: int = 120, color=(12, 12, 14)):
    """Render an expanding circular tactile shockwave on pinch lock-on."""
    if not (0.0 <= progress <= 1.0):
        return
    r = int(progress * max_radius)
    w = max(1, int((1.0 - progress) * 4))
    if r > 4:
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=color, width=w)
        # Peripheral radiating particle dots
        num_dots = 8
        for i in range(num_dots):
            angle = i * (2 * math.pi / num_dots)
            dot_dist = r + int(progress * 18)
            dx = int(cx + dot_dist * math.cos(angle))
            dy = int(cy + dot_dist * math.sin(angle))
            draw.ellipse([dx - 2, dy - 2, dx + 2, dy + 2], fill=color)


_GRAIN_CACHE = {}


def apply_cinematic_film_grain(img: Image.Image, frame_idx: int, intensity: float = 0.012) -> Image.Image:
    """Apply cached 35mm monochrome micro-grain plates to eliminate digital banding."""
    global _GRAIN_CACHE
    cache_key = (H, W, intensity)
    if cache_key not in _GRAIN_CACHE:
        rng = np.random.RandomState(42)
        _GRAIN_CACHE[cache_key] = [
            rng.normal(0.0, intensity * 255.0, (H, W, 1)).astype(np.float32)
            for _ in range(30)
        ]
    grain_plates = _GRAIN_CACHE[cache_key]
    plate = grain_plates[frame_idx % len(grain_plates)]
    arr = np.array(img, dtype=np.float32)
    arr = np.clip(arr + plate, 0.0, 255.0).astype(np.uint8)
    return Image.fromarray(arr, "RGB")


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
