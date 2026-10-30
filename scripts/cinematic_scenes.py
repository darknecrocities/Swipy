#!/usr/bin/env python3
"""Scene Renderers (Scenes 1 through 5) for Swipy 1080p Landscape Showcase Film.

Palette: Pure Studio White (#FFFFFF) Canvas with Stark Black (#0A0A0C) Accents.
Choreographed across 5 scenes:
- Scene 1: The M6 Touchscreen Premise & Touchless Morph
- Scene 2: Product Hero Reveal with Floating MacBook Pro Video
- Scene 3: 21-Joint Live Vision Tracking & Cursor Dynamics
- Scene 4: 18 Native Gestures Bento Grid & On-Device Security
- Scene 5: Marketable Product Finale & Call To Action

Complies strictly with SkillBuilder cognitive limits (<500 lines).
"""

import math
import os
from PIL import Image, ImageDraw, ImageFont

from cinematic_effects import (
    W, H, FONT_HEADING, FONT_SANS, FONT_MONO,
    draw_swiss_background, draw_hud_brackets, draw_reticle,
    draw_pill_badge, draw_macbook_bezel, ease_snap
)

SCRATCH_DIR = "/Users/arronkianparejas/.gemini/antigravity/brain/44f6a692-c641-4a23-bd30-b5abab155805/scratch"
FRAMES_HERO_DIR = os.path.join(SCRATCH_DIR, "frames_hero")
FRAMES_SANDBOX_DIR = os.path.join(SCRATCH_DIR, "frames_sandbox")

LOGO_PATH = "Resources/AppLogo.png"
MENUBAR_POPOVER_PATH = "assets/images/swipy-menubar-popover.png"


def load_cached_frame(folder: str, idx: int) -> Image.Image:
    """Safely load cached frame image from scratch directory."""
    files = sorted(os.listdir(folder))
    clamped_idx = max(0, min(len(files) - 1, idx))
    path = os.path.join(folder, files[clamped_idx])
    return Image.open(path).convert("RGB")


def render_scene_1(frame_idx: int) -> Image.Image:
    """Scene 1: The M6 Touchscreen Hook & Word/Shape Morph (Frames 0 - 180)."""
    img = Image.new("RGB", (W, H), (255, 255, 255))
    draw = ImageDraw.Draw(img)
    draw_swiss_background(draw, frame_idx)

    f_huge = ImageFont.truetype(FONT_HEADING, 72)
    f_large = ImageFont.truetype(FONT_HEADING, 54)
    f_sub = ImageFont.truetype(FONT_SANS, 30)
    f_mono = ImageFont.truetype(FONT_MONO, 22)

    # Part A: The Premise Hook (Frames 0 - 75)
    if frame_idx < 75:
        p_intro = ease_snap(min(1.0, frame_idx / 22.0))
        y_off = int((1.0 - p_intro) * 36)
        draw.text((W // 2, 430 + y_off), "WHAT IF THE NEW M6 MACBOOK", font=f_huge, fill=(10, 10, 12), anchor="mm")
        draw.text((W // 2, 530 + y_off), "WAS TOUCHSCREEN?", font=f_huge, fill=(10, 10, 12), anchor="mm")
        draw.text((W // 2, 630 + y_off), "Apple's biggest dream.", font=f_sub, fill=(110, 110, 122), anchor="mm")

        reticle_x = int(W // 2 + 320 * (1.0 - p_intro))
        draw_reticle(draw, reticle_x, 780, radius=44, pulsing=1.0 + 0.1 * math.sin(frame_idx * 0.25))
        draw_hud_brackets(draw, [W // 2 - 200, 720, W // 2 + 200, 840], color=(140, 140, 150))

    # Part B: The Twist (Frames 75 - 110)
    elif frame_idx < 110:
        draw.text((W // 2, 420), "BUT WHAT IF...", font=f_large, fill=(120, 120, 130), anchor="mm")
        draw.text((W // 2, 510), "YOU NEVER HAVE TO", font=f_huge, fill=(10, 10, 12), anchor="mm")
        draw.text((W // 2, 600), "TOUCH THE SCREEN?", font=f_huge, fill=(10, 10, 12), anchor="mm")
        draw_reticle(draw, W // 2, 750, radius=52, pulsing=1.0 + 0.2 * math.sin(frame_idx * 0.35))
        draw.text((W // 2, 830), "[ ZERO CONTACT • MAXIMUM INTUITION ]", font=f_mono, fill=(130, 130, 142), anchor="mm")

    # Part C: The Kinetic Shape Morph (Frames 110 - 180): TOUCHSCREEN -> TOUCHLESS
    else:
        p_morph = ease_snap((frame_idx - 110) / 28.0)
        draw.text((W // 2, 380), "THE TOUCHSCREEN FEEL.", font=f_large, fill=(120, 120, 130), anchor="mm")

        # Inverted Pitch Black Pill Badge with Pure White Typography
        f_pill = ImageFont.truetype(FONT_HEADING, 64)
        pill_w = int(760 * p_morph)
        pill_h = 120
        px0 = (W - pill_w) // 2
        py0 = 470
        px1 = px0 + pill_w
        py1 = py0 + pill_h

        if pill_w > 40:
            draw.rounded_rectangle([px0, py0, px1, py1], radius=60, fill=(10, 10, 12))
            if p_morph > 0.65:
                draw.text((W // 2, py0 + pill_h // 2), "TOUCHLESS.", font=f_pill, fill=(255, 255, 255), anchor="mm")

        draw_hud_brackets(draw, [px0 - 32, py0 - 20, px1 + 32, py1 + 20], color=(10, 10, 12), tick_len=26, width=3)
        draw.text((W // 2, 650), "[ ZERO SENSORS • 100% SPATIAL TRACKING • 30 FPS ]", font=f_mono, fill=(80, 80, 92), anchor="mm")

        # Concentric Sonar Ripple Rings
        ripple_r = int(((frame_idx - 110) * 10) % 280)
        draw.ellipse([W // 2 - ripple_r, 820 - ripple_r, W // 2 + ripple_r, 820 + ripple_r], outline=(200, 200, 212), width=2)
        draw_reticle(draw, W // 2, 820, radius=38, pulsing=1.0)
        draw.text((W // 2, 890), "STANDBY // READY TO GLIDE", font=f_mono, fill=(120, 120, 130), anchor="mm")

    return img


def render_scene_2(frame_idx: int) -> Image.Image:
    """Scene 2: Product Hero Reveal with Floating MacBook Pro Video (Frames 180 - 420)."""
    img = Image.new("RGB", (W, H), (255, 255, 255))
    draw = ImageDraw.Draw(img)
    draw_swiss_background(draw, frame_idx)

    f_title = ImageFont.truetype(FONT_HEADING, 76)
    f_body = ImageFont.truetype(FONT_SANS, 26)
    f_badge = ImageFont.truetype(FONT_HEADING, 20)
    f_mono = ImageFont.truetype(FONT_MONO, 20)

    # Left Column: Editorial Typography Stack (x: 120 to 760)
    draw.text((120, 220), "[ 2026 PRODUCT INTRODUCTION ]", font=f_mono, fill=(120, 120, 132))
    draw.text((120, 310), "MEET SWIPY.", font=f_title, fill=(10, 10, 12))

    lead_text_1 = "Your built-in MacBook camera is now"
    lead_text_2 = "a natural spatial trackpad."
    lead_text_3 = "Control any macOS app with a wave of your hand."
    draw.text((120, 420), lead_text_1, font=f_body, fill=(60, 60, 70))
    draw.text((120, 460), lead_text_2, font=f_body, fill=(60, 60, 70))
    draw.text((120, 500), lead_text_3, font=f_body, fill=(110, 110, 120))

    # Feature Badges Row
    draw_pill_badge(draw, "100% ON-DEVICE VISION", 280, 590, f_badge, bg_color=(10, 10, 12), text_color=(255, 255, 255))
    draw_pill_badge(draw, "< 12MS ZERO LATENCY", 560, 590, f_badge, bg_color=(234, 234, 240), text_color=(10, 10, 12))

    # Bottom Telemetry Spec Card
    draw_hud_brackets(draw, [120, 670, 740, 880], color=(180, 180, 190))
    draw.text((150, 705), "CORE INVARIANTS:", font=f_mono, fill=(10, 10, 12))
    draw.text((150, 745), "• Apple Vision Framework Native 21-Joint Inference", font=f_mono, fill=(80, 80, 90))
    draw.text((150, 785), "• Adaptive Power Curve Exponential Acceleration", font=f_mono, fill=(80, 80, 90))
    draw.text((150, 825), "• One-Euro Jitter Filter for Rock-Steady Micro Clicks", font=f_mono, fill=(80, 80, 90))

    # Right Column: Large MacBook Pro with Real Screen Demo (x: 820 to 1800, y: 150 to 930)
    raw_frame = load_cached_frame(FRAMES_HERO_DIR, frame_idx - 180)
    mb_box = [840, 160, 1780, 890]
    draw_macbook_bezel(img, raw_frame, mb_box)

    # Pixel Cursor Orb Floating Badge on Top-Right Corner
    orb_cx = 1730
    orb_cy = 210
    draw.ellipse([orb_cx - 44, orb_cy - 44, orb_cx + 44, orb_cy + 44], fill=(10, 10, 12))
    draw.text((orb_cx, orb_cy), "ORB", font=f_badge, fill=(255, 255, 255), anchor="mm")
    draw_reticle(draw, orb_cx, orb_cy, radius=52, pulsing=1.0, color=(10, 10, 12))

    return img


def render_scene_3(frame_idx: int) -> Image.Image:
    """Scene 3: 21-Joint Live Vision Tracking & Cursor Dynamics (Frames 420 - 720)."""
    img = Image.new("RGB", (W, H), (255, 255, 255))
    draw = ImageDraw.Draw(img)
    draw_swiss_background(draw, frame_idx)

    f_stamp = ImageFont.truetype(FONT_HEADING, 52)
    f_sub = ImageFont.truetype(FONT_SANS, 24)
    f_mono = ImageFont.truetype(FONT_MONO, 20)
    f_badge = ImageFont.truetype(FONT_HEADING, 20)

    # Left Column: Step Instruction & Telemetry (x: 120 to 760)
    if frame_idx < 520:
        step_num = "01 / POINT & GLIDE"
        step_desc = "Aim with your index finger to steer the macOS cursor."
    elif frame_idx < 620:
        step_num = "02 / PINCH TO GRAB"
        step_desc = "Touch thumb & index together to lock onto window titlebars."
    else:
        step_num = "03 / DRAG ANYWHERE"
        step_desc = "Fluid 1:1 window repositioning across multiple displays."

    draw.text((120, 220), step_num, font=f_stamp, fill=(10, 10, 12))
    draw.text((120, 290), step_desc, font=f_sub, fill=(90, 90, 100))

    # Real-Time Telemetry HUD Box
    tx = int(1280 + 160 * math.sin(frame_idx * 0.08))
    ty = int(520 + 90 * math.cos(frame_idx * 0.08))
    is_pinching = 520 <= frame_idx < 620

    draw_hud_brackets(draw, [120, 370, 740, 740], color=(160, 160, 172))
    status_text = "STATUS: PINCH & DRAG LOCKED" if is_pinching else "STATUS: POINTING INDEX TIP"
    draw.text((160, 420), status_text, font=f_mono, fill=(10, 10, 12))
    draw.text((160, 470), f"COORDINATES: X={tx:04d} • Y={ty:04d} • Z=0.84", font=f_mono, fill=(80, 80, 90))
    draw.text((160, 520), "VISION ENGINE: 21 Landmarks @ 30 FPS", font=f_mono, fill=(80, 80, 90))
    draw.text((160, 570), "SMOOTHER: One-Euro Adaptive Cutoff Active", font=f_mono, fill=(80, 80, 90))
    draw.text((160, 620), "DEAD ZONE: 4.5% Center Margin Stabilized", font=f_mono, fill=(80, 80, 90))

    pill_bg = (10, 10, 12) if is_pinching else (234, 234, 240)
    pill_fg = (255, 255, 255) if is_pinching else (10, 10, 12)
    draw_pill_badge(draw, "INDEX & THUMB TRACKING", 380, 680, f_badge, bg_color=pill_bg, text_color=pill_fg)

    # Right Column: Real Sandbox Footage with Camera Overlay (x: 800 to 1800)
    raw_frame = load_cached_frame(FRAMES_SANDBOX_DIR, frame_idx - 420)
    mb_box = [820, 160, 1780, 890]
    draw_macbook_bezel(img, raw_frame, mb_box)

    # Dynamic HUD Crosshair Reticle tracking simulated hand movement
    draw_reticle(draw, tx, ty, radius=34 if is_pinching else 44, pulsing=0.88 if is_pinching else 1.0, color=(10, 10, 12))
    draw_hud_brackets(draw, [tx - 50, ty - 50, tx + 50, ty + 50], color=(10, 10, 12) if is_pinching else (120, 120, 130))

    return img


def render_scene_4(frame_idx: int) -> Image.Image:
    """Scene 4: 18 Native Gestures Bento Grid & On-Device Security (Frames 720 - 1020)."""
    img = Image.new("RGB", (W, H), (255, 255, 255))
    draw = ImageDraw.Draw(img)
    draw_swiss_background(draw, frame_idx)

    f_title = ImageFont.truetype(FONT_HEADING, 54)
    f_sub = ImageFont.truetype(FONT_SANS, 24)
    f_mono = ImageFont.truetype(FONT_MONO, 18)
    f_badge = ImageFont.truetype(FONT_HEADING, 18)

    draw.text((W // 2, 140), "18 NATIVE MACOS GESTURES", font=f_title, fill=(10, 10, 12), anchor="mm")
    draw.text((W // 2, 190), "Hardware-level input synthesis with zero system extensions.", font=f_sub, fill=(90, 90, 100), anchor="mm")

    # Bento Card 1: Gestures Reference Table (Left: x: 120 to 760, y: 240 to 920)
    draw.rounded_rectangle([120, 240, 760, 920], radius=16, fill=(250, 250, 252), outline=(224, 224, 232), width=1)
    draw_hud_brackets(draw, [120, 240, 760, 920], color=(180, 180, 190))
    draw.text((150, 280), "CORE GESTURE CATALOG", font=f_mono, fill=(10, 10, 12))

    gestures = [
        ("4-Finger Horizontal Flick", "Switch Spaces (Mission Control)"),
        ("Index & Thumb Pinch", "Primary Click & Drag Window"),
        ("Two-Finger Tap", "Secondary / Right Click Action"),
        ("Fist Hold (Clenched)", "Emergency Tracking Pause"),
        ("Victory Sign (V-Hand)", "Toggle Swipy App Launcher"),
        ("Open Palm Hover", "Continuous Smooth Velocity Scroll"),
        ("Thumb Tap", "Double Click Selection"),
    ]
    for i, (g_name, g_desc) in enumerate(gestures):
        gy = 340 + i * 76
        draw.text((150, gy), f"• {g_name}", font=f_mono, fill=(10, 10, 12))
        draw.text((170, gy + 28), g_desc, font=f_sub, fill=(100, 100, 112))

    # Bento Card 2: macOS Menu Bar Popover Frame (Center: x: 800 to 1260, y: 240 to 920)
    draw.rounded_rectangle([800, 240, 1260, 920], radius=16, fill=(250, 250, 252), outline=(224, 224, 232), width=1)
    draw_hud_brackets(draw, [800, 240, 1260, 920], color=(180, 180, 190))
    draw.text((830, 280), "MENU BAR CONTROLLER", font=f_mono, fill=(10, 10, 12))

    if os.path.exists(MENUBAR_POPOVER_PATH):
        popover_img = Image.open(MENUBAR_POPOVER_PATH).convert("RGB")
        # Resize popover image to fit neatly
        pw, ph = 380, int(380 * popover_img.height / popover_img.width)
        popover_resized = popover_img.resize((pw, ph), Image.Resampling.BILINEAR)
        img.paste(popover_resized, (840, 330))

    # Bento Card 3: 100% On-Device Privacy Architecture (Right: x: 1300 to 1800, y: 240 to 920)
    draw.rounded_rectangle([1300, 240, 1800, 920], radius=16, fill=(10, 10, 12))
    draw_hud_brackets(draw, [1300, 240, 1800, 920], color=(255, 255, 255))

    draw.text((1340, 310), "ZERO CLOUD DATA", font=f_title, fill=(255, 255, 255))
    draw.text((1340, 370), "100% ON-DEVICE PRIVACY", font=f_mono, fill=(180, 180, 190))

    privacy_points = [
        "Camera video is processed in memory via Apple Vision.",
        "Zero images, frames, or biometric data are stored.",
        "Zero network connections. Operates fully offline.",
        "Sandboxed macOS app architecture.",
        "Independent 1-click Emergency Pause trigger.",
    ]
    for i, pt in enumerate(privacy_points):
        py = 440 + i * 72
        draw.text((1340, py), f"✓  {pt}", font=f_sub, fill=(220, 220, 230))

    draw_pill_badge(draw, "VERIFIED SECURE", 1550, 840, f_badge, bg_color=(255, 255, 255), text_color=(10, 10, 12))

    return img


def render_scene_5(frame_idx: int) -> Image.Image:
    """Scene 5: Marketable Product Finale & Call To Action (Frames 1020 - 1230)."""
    img = Image.new("RGB", (W, H), (255, 255, 255))
    draw = ImageDraw.Draw(img)
    draw_swiss_background(draw, frame_idx)

    f_huge = ImageFont.truetype(FONT_HEADING, 76)
    f_sub = ImageFont.truetype(FONT_SANS, 32)
    f_cta = ImageFont.truetype(FONT_HEADING, 28)
    f_mono = ImageFont.truetype(FONT_MONO, 24)

    # 1. Swipy App Logo at Top-Center
    if os.path.exists(LOGO_PATH):
        logo = Image.open(LOGO_PATH).convert("RGBA")
        logo_size = 110
        logo_resized = logo.resize((logo_size, logo_size), Image.Resampling.BILINEAR)
        lx = (W - logo_size) // 2
        ly = 200
        # Elevation shadow
        draw.rounded_rectangle([lx - 4, ly + 6, lx + logo_size + 4, ly + logo_size + 14], radius=24, fill=(224, 224, 232))
        img.paste(logo_resized, (lx, ly), logo_resized)

    # 2. Hero Closing Slogan
    draw.text((W // 2, 380), "CONTROL YOUR MAC.", font=f_huge, fill=(10, 10, 12), anchor="mm")

    # Inverted Black Pill Badge for Tagline
    draw_pill_badge(draw, "WITH A WAVE OF YOUR HAND.", W // 2, 480, f_huge, bg_color=(10, 10, 12), text_color=(255, 255, 255), pad_x=36, pad_y=16)

    draw.text((W // 2, 590), "Touchless spatial hand control for macOS. Works with your built-in camera.", font=f_sub, fill=(90, 90, 100), anchor="mm")

    # 3. Primary CTA: Download macOS DMG Button
    draw_pill_badge(draw, "DOWNLOAD MACOS DMG", W // 2, 700, f_cta, bg_color=(10, 10, 12), text_color=(255, 255, 255), pad_x=44, pad_y=18)
    draw_hud_brackets(draw, [W // 2 - 280, 650, W // 2 + 280, 750], color=(10, 10, 12), tick_len=24, width=3)

    # 4. Web Portal & GitHub Badges
    draw.text((W // 2, 810), "WEBSITE: GETSWIPY.VERCEL.APP", font=f_mono, fill=(10, 10, 12), anchor="mm")
    draw.text((W // 2, 860), "GITHUB: DARKNECROCITIES / SWIPY", font=f_mono, fill=(110, 110, 120), anchor="mm")

    # Subtle fade to white on the last 15 frames (1215 - 1230)
    if frame_idx >= 1215:
        p_fade = (frame_idx - 1215) / 15.0
        overlay = Image.new("RGB", (W, H), (255, 255, 255))
        img = Image.blend(img, overlay, p_fade)

    return img
