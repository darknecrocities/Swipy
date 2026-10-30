#!/usr/bin/env python3
"""Scene Renderers (Scenes 1 & 2) for Swipy Facebook Reels Showcase Film.

Complies strictly with SkillBuilder cognitive limits (<350 lines).
"""

import math
import os
from PIL import Image, ImageDraw, ImageFont

from reels_effects import (
    W, H, FONT_HEADING, FONT_SANS, FONT_MONO,
    draw_swiss_background, draw_hud_brackets, draw_reticle,
    draw_macbook_bezel, ease_snap
)

SCRATCH_DIR = "/Users/arronkianparejas/.gemini/antigravity/brain/44f6a692-c641-4a23-bd30-b5abab155805/scratch"
FRAMES_HERO_DIR = os.path.join(SCRATCH_DIR, "frames_hero")


def load_hero_frame(idx: int) -> Image.Image:
    """Safely load cached frame image from hero scratch directory."""
    files = sorted(os.listdir(FRAMES_HERO_DIR))
    clamped_idx = max(0, min(len(files) - 1, idx))
    path = os.path.join(FRAMES_HERO_DIR, files[clamped_idx])
    return Image.open(path).convert("RGB")



def render_scene_1(frame_idx: int) -> Image.Image:
    """Scene 1: The M6 Touchscreen Hook & Word/Shape Morph (Frames 0 - 150)."""
    img = Image.new("RGB", (W, H), (0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_swiss_background(draw, frame_idx)

    f_huge = ImageFont.truetype(FONT_HEADING, 74)
    f_large = ImageFont.truetype(FONT_HEADING, 62)
    f_sub = ImageFont.truetype(FONT_SANS, 34)
    f_mono = ImageFont.truetype(FONT_MONO, 26)

    # Question Hook (Frames 0 - 65)
    if frame_idx < 65:
        p_intro = ease_snap(min(1.0, frame_idx / 20.0))
        y_offset = int((1.0 - p_intro) * 40)
        draw.text((W // 2, 680 + y_offset), "WHAT IF THE NEW M6", font=f_huge, fill=(255, 255, 255), anchor="mm")
        draw.text((W // 2, 780 + y_offset), "WAS TOUCHSCREEN?", font=f_huge, fill=(255, 255, 255), anchor="mm")
        draw.text((W // 2, 880 + y_offset), "Apple's biggest dream.", font=f_sub, fill=(160, 160, 160), anchor="mm")

        # Approaching finger reticle
        reticle_y = int(1200 - p_intro * 180)
        draw_reticle(draw, W // 2, reticle_y, radius=48, pulsing=1.0 + 0.1 * math.sin(frame_idx * 0.3))
        draw_hud_brackets(draw, [W // 2 - 160, reticle_y - 80, W // 2 + 160, reticle_y + 80], color=(140, 140, 140))

    # The Twist (Frames 65 - 90)
    elif frame_idx < 90:
        draw.text((W // 2, 700), "BUT WHAT IF...", font=f_large, fill=(160, 160, 160), anchor="mm")
        draw.text((W // 2, 800), "YOU NEVER HAVE TO", font=f_huge, fill=(255, 255, 255), anchor="mm")
        draw.text((W // 2, 900), "TOUCH THE SCREEN?", font=f_huge, fill=(255, 255, 255), anchor="mm")
        draw_reticle(draw, W // 2, 1150, radius=56, pulsing=1.0 + 0.2 * math.sin(frame_idx * 0.4))

    # The Word & Shape Morph (Frames 90 - 150): TOUCHSCREEN -> TOUCHLESS
    else:
        p_morph = ease_snap((frame_idx - 90) / 25.0)
        draw.text((W // 2, 600), "THE TOUCHSCREEN FEEL.", font=f_large, fill=(180, 180, 180), anchor="mm")

        # Morphing Pill Badge: Inverted Stark White with Black Text
        f_pill = ImageFont.truetype(FONT_HEADING, 66)
        pill_w = int(720 * p_morph)
        pill_h = 130
        px0 = (W - pill_w) // 2
        py0 = 740
        px1 = px0 + pill_w
        py1 = py0 + pill_h

        if pill_w > 40:
            draw.rounded_rectangle([px0, py0, px1, py1], radius=65, fill=(255, 255, 255))
            if p_morph > 0.6:
                draw.text((W // 2, py0 + pill_h // 2), "TOUCHLESS.", font=f_pill, fill=(0, 0, 0), anchor="mm")

        # HUD Lock-on Brackets & Monospace Readout
        draw_hud_brackets(draw, [px0 - 30, py0 - 24, px1 + 30, py1 + 24], color=(255, 255, 255), tick_len=25, width=3)
        draw.text((W // 2, 940), "[ ZERO CONTACT • 100% SPATIAL TRACKING ]", font=f_mono, fill=(200, 200, 200), anchor="mm")

        # Expanding Sonar Ripple Rings
        ripple_r = int(((frame_idx - 90) * 8) % 360)
        draw.ellipse([W // 2 - ripple_r, 1260 - ripple_r, W // 2 + ripple_r, 1260 + ripple_r], outline=(60, 60, 60), width=2)
        draw_reticle(draw, W // 2, 1260, radius=44, pulsing=1.0)
        draw.text((W // 2, 1340), "READY TO GLIDE", font=f_mono, fill=(160, 160, 160), anchor="mm")

    return img


def render_scene_2(frame_idx: int, raw_frame: Image.Image = None) -> Image.Image:
    """Scene 2: Meet Swipy & Real MacBook Demo Footage (Frames 150 - 360)."""
    if raw_frame is None:
        raw_frame = load_hero_frame(frame_idx - 150)
    img = Image.new("RGB", (W, H), (0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_swiss_background(draw, frame_idx)

    f_title = ImageFont.truetype(FONT_HEADING, 82)
    f_sub = ImageFont.truetype(FONT_SANS, 34)
    f_mono = ImageFont.truetype(FONT_MONO, 24)

    # Top Header Typography
    draw.text((W // 2, 230), "MEET SWIPY.", font=f_title, fill=(255, 255, 255), anchor="mm")
    draw.rounded_rectangle([W // 2 - 320, 290, W // 2 + 320, 346], radius=28, fill=(255, 255, 255))
    draw.text((W // 2, 318), "BUILT-IN MACBOOK CAMERA", font=f_mono, fill=(0, 0, 0), anchor="mm")
    draw.text((W // 2, 380), "ZERO RINGS • ZERO GLOVES • ZERO HARDWARE", font=f_sub, fill=(170, 170, 170), anchor="mm")

    # Center: Floating MacBook Pro Hardware Bezel with Real User Recording
    macbook_box = [60, 430, W - 60, 1040]
    draw_macbook_bezel(img, raw_frame, macbook_box)

    # Bottom Telemetry HUD Cards
    draw_hud_brackets(draw, [60, 1090, W - 60, 1370], color=(100, 100, 100))
    draw.text((100, 1140), "NATURAL SPATIAL TRACKPAD", font=f_mono, fill=(255, 255, 255))
    draw.text((100, 1185), "Turns any M-series or Intel MacBook into a touchless trackpad.", font=f_sub, fill=(180, 180, 180))
    draw.text((100, 1235), "Glide cursor with index finger • Pinch to grab windows.", font=f_sub, fill=(150, 150, 150))

    # Real-time metrics chip row
    draw.rounded_rectangle([100, 1280, 360, 1330], radius=12, fill=(24, 24, 24), outline=(50, 50, 50))
    draw.text((230, 1305), "30 FPS APPLE VISION", font=f_mono, fill=(240, 240, 240), anchor="mm")

    draw.rounded_rectangle([380, 1280, 640, 1330], radius=12, fill=(24, 24, 24), outline=(50, 50, 50))
    draw.text((510, 1305), "6.6MS FRAME TIME", font=f_mono, fill=(240, 240, 240), anchor="mm")

    draw.rounded_rectangle([660, 1280, 980, 1330], radius=12, fill=(24, 24, 24), outline=(50, 50, 50))
    draw.text((820, 1305), "100% ON-DEVICE", font=f_mono, fill=(240, 240, 240), anchor="mm")

    return img
