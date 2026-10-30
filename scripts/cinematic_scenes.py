#!/usr/bin/env python3
"""Organic Scene Choreographer for Swipy 1080p Landscape Commercial Film.

Directorial Vision:
- Pure Studio White (#FFFFFF) Canvas with Stark Black (#0A0A0C) Accents.
- Zero static debug HUD banners, zero bracket soup, zero artificial '// tags'.
- Real application footage & screenshots: live camera feed, native gesture cards, menu bar popover, settings panel.
- Dynamic camera shift (pan + slow push-in zoom) and organic spotlight highlights on each scene.
- Beat-locked 64.0s duration (1920 frames @ 30 FPS across 6 scenes).

Complies strictly with SkillBuilder cognitive limits (<500 lines).
"""

import math
import os
from PIL import Image, ImageDraw, ImageFont

from cinematic_effects import (
    W, H, FONT_HEADING, FONT_SANS, FONT_MONO,
    draw_studio_background, draw_pill_badge, draw_macbook_bezel,
    draw_vector_check, draw_specular_sheen, draw_shockwave_ring,
    draw_dynamic_highlight, apply_camera_shift, ease_snap
)

SCRATCH_DIR = "/Users/arronkianparejas/.gemini/antigravity/brain/44f6a692-c641-4a23-bd30-b5abab155805/scratch"
FRAMES_HERO_DIR = os.path.join(SCRATCH_DIR, "frames_hero")

LOGO_PATH = "Resources/AppLogo.png"
CAMERA_FEED_PATH = "assets/images/swipy-overview-camera-feed.png"
GESTURE_CARDS_PATH = "assets/images/swipy-gesture-cards-native.png"
MENUBAR_POPOVER_PATH = "assets/images/swipy-menubar-popover.png"
CURSOR_SETTINGS_PATH = "assets/images/swipy-cursor-settings.png"


def load_cached_frame(folder: str, idx: int) -> Image.Image:
    """Safely load cached frame image from scratch directory."""
    files = sorted(os.listdir(folder))
    clamped_idx = max(0, min(len(files) - 1, idx))
    path = os.path.join(folder, files[clamped_idx])
    return Image.open(path).convert("RGB")


def draw_macos_window_card(canvas_img: Image.Image, content_img: Image.Image, box, title: str = ""):
    """Render an authentic elevated macOS window frame with native traffic lights."""
    draw = ImageDraw.Draw(canvas_img)
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0

    # Soft ambient elevation shadow
    draw.rounded_rectangle([x0 - 6, y0 + 10, x1 + 6, y1 + 18], radius=18, fill=(232, 232, 240))
    # Outer window chassis
    draw.rounded_rectangle(box, radius=16, fill=(255, 255, 255), outline=(220, 220, 230), width=1)

    # Native Title Bar
    tb_h = 36
    draw.rounded_rectangle([x0, y0, x1, y0 + tb_h], radius=16, fill=(246, 246, 250))
    draw.rectangle([x0, y0 + 16, x1, y0 + tb_h], fill=(246, 246, 250))
    draw.line([(x0, y0 + tb_h), (x1, y0 + tb_h)], fill=(225, 225, 235), width=1)

    # macOS Traffic Lights (Red, Yellow, Green)
    draw.ellipse([x0 + 16, y0 + 13, x0 + 26, y0 + 23], fill=(255, 95, 86))
    draw.ellipse([x0 + 34, y0 + 13, x0 + 44, y0 + 23], fill=(254, 188, 46))
    draw.ellipse([x0 + 52, y0 + 13, x0 + 62, y0 + 23], fill=(40, 200, 64))

    if title:
        f_tb = ImageFont.truetype(FONT_SANS, 14)
        draw.text(((x0 + x1) // 2, y0 + 18), title, font=f_tb, fill=(90, 90, 100), anchor="mm")

    # Resize content image and paste into window body
    cw, ch = w - 4, h - tb_h - 4
    resized = content_img.resize((cw, ch), Image.Resampling.BILINEAR)
    canvas_img.paste(resized, (x0 + 2, y0 + tb_h + 2))


def render_scene_1(frame_idx: int) -> Image.Image:
    """Scene 1: The Touchless Vision & Kinetic Morph (Frames 0 - 240, 8s)."""
    img = Image.new("RGB", (W, H), (255, 255, 255))
    draw = ImageDraw.Draw(img)
    draw_studio_background(draw, frame_idx)

    f_huge = ImageFont.truetype(FONT_HEADING, 72)
    f_large = ImageFont.truetype(FONT_HEADING, 52)
    f_sub = ImageFont.truetype(FONT_SANS, 30)

    rel_frame = frame_idx

    # Part A: The Vision Question (Frames 0 - 110)
    if rel_frame < 110:
        p_intro = ease_snap(min(1.0, rel_frame / 36.0))
        y_off = int((1.0 - p_intro) * 35)
        draw.text((W // 2, 420 + y_off), "WHAT IF YOUR MAC", font=f_huge, fill=(10, 10, 12), anchor="mm")
        draw.text((W // 2, 525 + y_off), "COULD UNDERSTAND YOUR HANDS?", font=f_huge, fill=(10, 10, 12), anchor="mm")
        draw.text((W // 2, 630 + y_off), "Not by reaching out to touch the glass.", font=f_sub, fill=(110, 110, 122), anchor="mm")

    # Part B: The Kinetic Reveal (Frames 110 - 240)
    else:
        p_morph = ease_snap(min(1.0, (rel_frame - 110) / 36.0))
        draw.text((W // 2, 385), "THROUGH THE NATURAL AIR IN FRONT OF YOU.", font=f_large, fill=(110, 110, 122), anchor="mm")

        # Inverted Pitch Black Pill Badge with Pure White Typography
        f_pill = ImageFont.truetype(FONT_HEADING, 66)
        pill_w = int(720 * p_morph)
        pill_h = 120
        px0, py0 = (W - pill_w) // 2, 480
        px1, py1 = px0 + pill_w, py0 + pill_h

        if pill_w > 40:
            draw.rounded_rectangle([px0, py0, px1, py1], radius=60, fill=(10, 10, 12))
            if p_morph > 0.65:
                draw.text((W // 2, py0 + pill_h // 2), "TOUCHLESS.", font=f_pill, fill=(255, 255, 255), anchor="mm")
                # Specular sheen gliding across black pill
                sheen_p = (rel_frame - 145) / 50.0
                draw_specular_sheen(img, [px0, py0, px1, py1], sheen_p)

        # Concentric Soft Acoustic Wavefield
        ripple_r = int(((rel_frame - 110) * 8) % 240)
        draw.ellipse([W // 2 - ripple_r, 790 - ripple_r, W // 2 + ripple_r, 790 + ripple_r], outline=(210, 210, 224), width=2)
        draw.text((W // 2, 850), "Pure Spatial Control for macOS", font=f_sub, fill=(110, 110, 122), anchor="mm")

    return apply_camera_shift(img, rel_frame, 240, zoom_amount=0.03, pan_x_amount=10.0, pan_y_amount=6.0)


def render_scene_2(frame_idx: int) -> Image.Image:
    """Scene 2: Product Hero Reveal with Floating 3D MacBook Pro (Frames 240 - 600, 12s)."""
    img = Image.new("RGB", (W, H), (255, 255, 255))
    draw = ImageDraw.Draw(img)
    draw_studio_background(draw, frame_idx)

    rel_frame = frame_idx - 240
    f_title = ImageFont.truetype(FONT_HEADING, 76)
    f_body = ImageFont.truetype(FONT_SANS, 26)
    f_sub = ImageFont.truetype(FONT_SANS, 22)
    f_badge = ImageFont.truetype(FONT_HEADING, 18)

    # Left Column: Editorial Typography Stack
    draw.text((120, 280), "MEET SWIPY.", font=f_title, fill=(10, 10, 12))
    draw.text((120, 390), "A native macOS app that transforms your FaceTime camera", font=f_body, fill=(50, 50, 60))
    draw.text((120, 435), "into an intelligent spatial trackpad.", font=f_body, fill=(50, 50, 60))
    draw.text((120, 500), "No sensors to wear. No extra hardware. Just pure, fluid control.", font=f_sub, fill=(100, 100, 110))

    # Feature Badges Row
    draw_pill_badge(draw, "100% ON-DEVICE VISION", 280, 595, f_badge, bg_color=(10, 10, 12), text_color=(255, 255, 255))
    draw_pill_badge(draw, "< 7MS ULTRA-LOW LATENCY", 560, 595, f_badge, bg_color=(240, 240, 246), text_color=(10, 10, 12))

    # Floating 3D MacBook Pro with Real Video Playback
    drift_x = int(6.0 * math.sin(rel_frame * 0.04))
    drift_y = int(5.0 * math.cos(rel_frame * 0.04))
    mb_box = [820 + drift_x, 150 + drift_y, 1780 + drift_x, 890 + drift_y]

    raw_frame = load_cached_frame(FRAMES_HERO_DIR, rel_frame)
    draw_macbook_bezel(img, raw_frame, mb_box)

    # Anamorphic Specular Sheen Glint across screen and aluminum bezel
    sheen_p = (rel_frame - 30) / 80.0
    draw_specular_sheen(img, mb_box, sheen_p)

    # Dynamic Spotlight Highlight around camera notch on activation
    if 20 <= rel_frame < 120:
        notch_cx = (mb_box[0] + mb_box[2]) // 2
        notch_cy = mb_box[1] + 20
        draw_dynamic_highlight(img, notch_cx, notch_cy, radius=90, intensity=0.35, color=(0, 122, 255))

    return apply_camera_shift(img, rel_frame, 360, zoom_amount=0.035, pan_x_amount=-15.0, pan_y_amount=8.0)


def render_scene_3(frame_idx: int) -> Image.Image:
    """Scene 3: Real 21-Joint Camera Feed & Cursor Precision (Frames 600 - 960, 12s)."""
    img = Image.new("RGB", (W, H), (255, 255, 255))
    draw = ImageDraw.Draw(img)
    draw_studio_background(draw, frame_idx)

    rel_frame = frame_idx - 600
    f_title = ImageFont.truetype(FONT_HEADING, 58)
    f_body = ImageFont.truetype(FONT_SANS, 24)
    f_step_num = ImageFont.truetype(FONT_HEADING, 20)
    f_step_text = ImageFont.truetype(FONT_SANS, 20)

    # Left Column: Precision Interaction Guide
    draw.text((120, 220), "SUB-MILLIMETER", font=f_title, fill=(10, 10, 12))
    draw.text((120, 290), "PRECISION.", font=f_title, fill=(10, 10, 12))

    draw.text((120, 380), "Glide your index finger to steer the cursor across displays.", font=f_body, fill=(60, 60, 70))
    draw.text((120, 420), "Touch thumb and index together to grab, lock on, and drag.", font=f_body, fill=(60, 60, 70))

    # Clean Steps Stack
    steps = [
        ("01", "Point Index Finger to Glide"),
        ("02", "Pinch Thumb & Index to Grab"),
        ("03", "Release to Drop Windows Naturally"),
    ]
    is_pinching = 100 <= rel_frame < 260
    for i, (num, desc) in enumerate(steps):
        sy = 490 + i * 75
        active = (i == 1 and is_pinching) or (i == 0 and not is_pinching)
        bg = (10, 10, 12) if active else (240, 240, 246)
        fg = (255, 255, 255) if active else (10, 10, 12)
        draw.rounded_rectangle([120, sy, 164, sy + 44], radius=10, fill=bg)
        draw.text((142, sy + 22), num, font=f_step_num, fill=fg, anchor="mm")
        draw.text((180, sy + 22), desc, font=f_step_text, fill=(10, 10, 12) if active else (110, 110, 120), anchor="lm")

    # Right Column: Real Application Camera Feed
    drift_y = int(4.0 * math.cos(rel_frame * 0.05))
    cam_box = [820, 170 + drift_y, 1800, 890 + drift_y]

    if os.path.exists(CAMERA_FEED_PATH):
        cam_img = Image.open(CAMERA_FEED_PATH).convert("RGB")
        draw_macos_window_card(img, cam_img, cam_box, "Swipy — Live 21-Joint Spatial Tracking")

    # Dynamic Spotlight Highlight & Tactile Shockwave on Pinch
    if is_pinching:
        pinch_cx, pinch_cy = 1380, 520 + drift_y
        draw_dynamic_highlight(img, pinch_cx, pinch_cy, radius=120, intensity=0.45, color=(0, 122, 255))
        p_shock = min(1.0, (rel_frame - 100) / 45.0)
        draw_shockwave_ring(draw, pinch_cx, pinch_cy, p_shock, max_radius=110, color=(10, 10, 12))

    return apply_camera_shift(img, rel_frame, 360, zoom_amount=0.035, pan_x_amount=15.0, pan_y_amount=-6.0)


def render_scene_4(frame_idx: int) -> Image.Image:
    """Scene 4: 18 Native Gestures with Real UI Cards & Menu Bar (Frames 960 - 1320, 12s)."""
    img = Image.new("RGB", (W, H), (255, 255, 255))
    draw = ImageDraw.Draw(img)
    draw_studio_background(draw, frame_idx)

    rel_frame = frame_idx - 960
    f_title = ImageFont.truetype(FONT_HEADING, 54)
    f_sub = ImageFont.truetype(FONT_SANS, 22)

    draw.text((W // 2, 105), "18 NATIVE MACOS GESTURES", font=f_title, fill=(10, 10, 12), anchor="mm")
    draw.text((W // 2, 155), "Swipe four fingers to switch Spaces. Tap, scroll, or freeze tracking with natural ergonomics.", font=f_sub, fill=(90, 90, 100), anchor="mm")

    # Display Real Native Gesture Cards & Real Menu Bar Popover
    p_float = int(4.0 * math.sin(rel_frame * 0.05))
    cards_box = [100, 205 + p_float, 1240, 925 + p_float]
    popover_box = [1280, 205 - p_float, 1820, 925 - p_float]

    if os.path.exists(GESTURE_CARDS_PATH):
        cards_img = Image.open(GESTURE_CARDS_PATH).convert("RGB")
        draw_macos_window_card(img, cards_img, cards_box, "Swipy Settings — Native Gesture Library")

    if os.path.exists(MENUBAR_POPOVER_PATH):
        popover_img = Image.open(MENUBAR_POPOVER_PATH).convert("RGB")
        draw_macos_window_card(img, popover_img, popover_box, "Menu Bar Quick Controller")

    # Dynamic Spotlight Highlight Shifting across Active Gestures
    # Frames 0-120: Highlight Space switch card; 120-240: Highlight pinch card; 240-360: Menu bar
    if rel_frame < 120:
        draw_dynamic_highlight(img, 420, 420 + p_float, radius=130, intensity=0.35, color=(0, 122, 255))
    elif rel_frame < 240:
        draw_dynamic_highlight(img, 820, 420 + p_float, radius=130, intensity=0.35, color=(0, 122, 255))
    else:
        draw_dynamic_highlight(img, 1550, 480 - p_float, radius=140, intensity=0.35, color=(0, 122, 255))

    return apply_camera_shift(img, rel_frame, 360, zoom_amount=0.03, pan_x_amount=-12.0, pan_y_amount=6.0)


def render_scene_5(frame_idx: int) -> Image.Image:
    """Scene 5: 100% On-Device Privacy & Real Settings Panel (Frames 1320 - 1620, 10s)."""
    img = Image.new("RGB", (W, H), (255, 255, 255))
    draw = ImageDraw.Draw(img)
    draw_studio_background(draw, frame_idx)

    rel_frame = frame_idx - 1320
    f_title = ImageFont.truetype(FONT_HEADING, 56)
    f_sub = ImageFont.truetype(FONT_SANS, 24)
    f_point = ImageFont.truetype(FONT_SANS, 20)

    # Left Column: Privacy Directives Stack
    draw.text((120, 220), "100% ON-DEVICE", font=f_title, fill=(10, 10, 12))
    draw.text((120, 290), "PRIVACY.", font=f_title, fill=(10, 10, 12))
    draw.text((120, 375), "Zero video leaves your Mac. Zero cloud lag. Pure privacy.", font=f_sub, fill=(90, 90, 100))

    privacy_points = [
        "In-Memory Processing via Apple Vision Framework",
        "Zero Video Frames or Biometric Data Stored",
        "Operates 100% Offline with Zero Network Permissions",
        "Sandboxed Native macOS Application Architecture",
    ]
    for i, pt in enumerate(privacy_points):
        py = 460 + i * 75
        draw_vector_check(draw, cx=145, cy=py + 12, radius=12, badge_color=(10, 10, 12), check_color=(255, 255, 255), width=2)
        draw.text((175, py), pt, font=f_point, fill=(20, 20, 24))

    # Right Column: Real Settings Panel
    drift_x = int(5.0 * math.sin(rel_frame * 0.05))
    settings_box = [840 + drift_x, 190, 1800 + drift_x, 880]

    if os.path.exists(CURSOR_SETTINGS_PATH):
        settings_img = Image.open(CURSOR_SETTINGS_PATH).convert("RGB")
        draw_macos_window_card(img, settings_img, settings_box, "Swipy Settings — Cursor Acceleration & Sensitivity")

    # Dynamic Spotlight Highlight sweeping over Sensitivity & Motion Smoothing
    draw_dynamic_highlight(img, 1320 + drift_x, 500, radius=130, intensity=0.32, color=(0, 122, 255))

    return apply_camera_shift(img, rel_frame, 300, zoom_amount=0.03, pan_x_amount=12.0, pan_y_amount=-5.0)


def render_scene_6(frame_idx: int) -> Image.Image:
    """Scene 6: Commercial Finale & Invitation (Frames 1620 - 1920, 10s)."""
    img = Image.new("RGB", (W, H), (255, 255, 255))
    draw = ImageDraw.Draw(img)
    draw_studio_background(draw, frame_idx)

    rel_frame = frame_idx - 1620
    f_title = ImageFont.truetype(FONT_HEADING, 66)
    f_sub = ImageFont.truetype(FONT_SANS, 26)
    f_btn = ImageFont.truetype(FONT_HEADING, 22)
    f_url = ImageFont.truetype(FONT_MONO, 19)

    # Ambient Glowing Halo behind App Logo
    halo_pulse = 1.0 + 0.15 * math.sin(rel_frame * 0.1)
    halo_r = int(95 * halo_pulse)
    draw.ellipse([W // 2 - halo_r, 220 - halo_r, W // 2 + halo_r, 220 + halo_r], fill=(236, 238, 248))

    # Centered High-Res App Logo
    if os.path.exists(LOGO_PATH):
        logo_img = Image.open(LOGO_PATH).convert("RGBA")
        logo_resized = logo_img.resize((120, 120), Image.Resampling.BILINEAR)
        img.paste(logo_resized, (W // 2 - 60, 160), logo_resized)

    # Primary Tagline & Pill
    draw.text((W // 2, 355), "CONTROL YOUR MAC.", font=f_title, fill=(10, 10, 12), anchor="mm")
    draw_pill_badge(draw, "WITH A WAVE OF YOUR HAND.", W // 2, 455, f_title, bg_color=(10, 10, 12), text_color=(255, 255, 255), pad_x=40, pad_y=16)

    # Primary Action CTA Button with Pulsing Light Ring
    btn_box = [W // 2 - 250, 575, W // 2 + 250, 660]
    draw.rounded_rectangle([btn_box[0] - 6, btn_box[1] - 6, btn_box[2] + 6, btn_box[3] + 6], radius=48, fill=(235, 238, 250))
    draw.rounded_rectangle(btn_box, radius=42, fill=(10, 10, 12))
    draw.text((W // 2, 618), "DOWNLOAD SWIPY FOR MACOS", font=f_btn, fill=(255, 255, 255), anchor="mm")

    # Links & Platform Compatibility
    draw.text((W // 2, 730), "Free & Open Source • Built for Apple Silicon & Intel", font=f_sub, fill=(110, 110, 120), anchor="mm")
    draw.text((W // 2, 785), "getswipy.vercel.app  •  github.com/darknecrocities/Swipy", font=f_url, fill=(30, 30, 35), anchor="mm")

    # Optical Fade to Pure White over final 30 frames
    if rel_frame > 270:
        p_fade = min(1.0, (rel_frame - 270) / 30.0)
        overlay = Image.new("RGBA", (W, H), (255, 255, 255, int(p_fade * 255)))
        img.paste(overlay, (0, 0), overlay)

    return apply_camera_shift(img, rel_frame, 300, zoom_amount=0.025, pan_x_amount=8.0, pan_y_amount=4.0)
