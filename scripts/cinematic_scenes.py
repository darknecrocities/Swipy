#!/usr/bin/env python3
"""Scene Renderers (Scenes 1 through 6) for Swipy 1080p Landscape Showcase Film.

Directorial Palette: Pure Studio White (#FFFFFF) Canvas with Stark Black (#0A0A0C) Accents.
Choreographed across 6 scenes (64.0s / 1920 frames total @ 30 FPS):
- Scene 1: The M6 Touchscreen Paradox & 3D Wavefield Morph (Frames 0 - 300)
- Scene 2: Floating 3D MacBook Pro Reveal with Anamorphic Glint (Frames 300 - 660)
- Scene 3: 21-Joint Biometric Skeleton Tracking & Tactile Shockwaves (Frames 660 - 1080)
- Scene 4: 18 Native Gestures Bento Grid & Parallax HUD (Frames 1080 - 1440)
- Scene 5: Apple Neural Engine Architecture & Settings Deep Dive (Frames 1440 - 1680)
- Scene 6: Cinematic Commercial Finale & Pulsing Invitation (Frames 1680 - 1920)

Complies strictly with SkillBuilder cognitive limits (<500 lines).
"""

import math
import os
from PIL import Image, ImageDraw, ImageFont

from cinematic_effects import (
    W, H, FONT_HEADING, FONT_SANS, FONT_MONO,
    draw_swiss_background, draw_hud_brackets, draw_reticle,
    draw_pill_badge, draw_macbook_bezel, draw_vector_check,
    draw_specular_sheen, draw_skeletal_hand_21, draw_shockwave_ring,
    ease_snap
)

SCRATCH_DIR = "/Users/arronkianparejas/.gemini/antigravity/brain/44f6a692-c641-4a23-bd30-b5abab155805/scratch"
FRAMES_HERO_DIR = os.path.join(SCRATCH_DIR, "frames_hero")
FRAMES_SANDBOX_DIR = os.path.join(SCRATCH_DIR, "frames_sandbox")

LOGO_PATH = "Resources/AppLogo.png"
MENUBAR_POPOVER_PATH = "assets/images/swipy-menubar-popover.png"
CURSOR_SETTINGS_PATH = "assets/images/swipy-cursor-settings.png"


def load_cached_frame(folder: str, idx: int) -> Image.Image:
    """Safely load cached frame image from scratch directory."""
    files = sorted(os.listdir(folder))
    clamped_idx = max(0, min(len(files) - 1, idx))
    path = os.path.join(folder, files[clamped_idx])
    return Image.open(path).convert("RGB")


def render_scene_1(frame_idx: int) -> Image.Image:
    """Scene 1: The M6 Touchscreen Hook & Kinetic Morph (Frames 0 - 300, 10s)."""
    img = Image.new("RGB", (W, H), (255, 255, 255))
    draw = ImageDraw.Draw(img)
    draw_swiss_background(draw, frame_idx)

    f_huge = ImageFont.truetype(FONT_HEADING, 74)
    f_large = ImageFont.truetype(FONT_HEADING, 54)
    f_sub = ImageFont.truetype(FONT_SANS, 30)
    f_mono = ImageFont.truetype(FONT_MONO, 22)

    # Part A: The Premise Hook (Frames 0 - 100)
    if frame_idx < 100:
        p_intro = ease_snap(min(1.0, frame_idx / 32.0))
        y_off = int((1.0 - p_intro) * 40)
        draw.text((W // 2, 420 + y_off), "WHAT IF THE NEW M6 MACBOOK", font=f_huge, fill=(10, 10, 12), anchor="mm")
        draw.text((W // 2, 524 + y_off), "WAS TOUCHSCREEN?", font=f_huge, fill=(10, 10, 12), anchor="mm")
        draw.text((W // 2, 626 + y_off), "Apple's biggest dream.", font=f_sub, fill=(110, 110, 122), anchor="mm")

        reticle_x = int(W // 2 + 340 * (1.0 - p_intro))
        draw_reticle(draw, reticle_x, 780, radius=46, pulsing=1.0 + 0.12 * math.sin(frame_idx * 0.25))
        draw_hud_brackets(draw, [W // 2 - 210, 715, W // 2 + 210, 845], color=(140, 140, 150))

    # Part B: The Twist (Frames 100 - 170)
    elif frame_idx < 170:
        draw.text((W // 2, 415), "BUT WHAT IF...", font=f_large, fill=(120, 120, 130), anchor="mm")
        draw.text((W // 2, 508), "YOU NEVER HAVE TO", font=f_huge, fill=(10, 10, 12), anchor="mm")
        draw.text((W // 2, 600), "TOUCH THE SCREEN?", font=f_huge, fill=(10, 10, 12), anchor="mm")
        draw_reticle(draw, W // 2, 750, radius=52, pulsing=1.0 + 0.2 * math.sin(frame_idx * 0.35))
        draw.text((W // 2, 835), "[ ZERO CONTACT • MAXIMUM INTUITION ]", font=f_mono, fill=(130, 130, 142), anchor="mm")

    # Part C: The Kinetic Shape Morph (Frames 170 - 300): TOUCHSCREEN -> TOUCHLESS
    else:
        p_morph = ease_snap((frame_idx - 170) / 36.0)
        draw.text((W // 2, 375), "THE TOUCHSCREEN FEEL.", font=f_large, fill=(120, 120, 130), anchor="mm")

        # Inverted Pitch Black Pill Badge with Pure White Typography
        f_pill = ImageFont.truetype(FONT_HEADING, 66)
        pill_w = int(780 * p_morph)
        pill_h = 124
        px0, py0 = (W - pill_w) // 2, 465
        px1, py1 = px0 + pill_w, py0 + pill_h

        if pill_w > 40:
            draw.rounded_rectangle([px0, py0, px1, py1], radius=62, fill=(10, 10, 12))
            if p_morph > 0.65:
                draw.text((W // 2, py0 + pill_h // 2), "TOUCHLESS.", font=f_pill, fill=(255, 255, 255), anchor="mm")
                # Specular sheen gliding across black pill
                sheen_p = (frame_idx - 200) / 45.0
                draw_specular_sheen(img, [px0, py0, px1, py1], sheen_p)

        draw_hud_brackets(draw, [px0 - 32, py0 - 20, px1 + 32, py1 + 20], color=(10, 10, 12), tick_len=26, width=3)
        draw.text((W // 2, 650), "[ ZERO SENSORS • 100% SPATIAL TRACKING • 30 FPS ]", font=f_mono, fill=(80, 80, 92), anchor="mm")

        # Concentric Sonar Ripple Rings
        ripple_r = int(((frame_idx - 170) * 8) % 280)
        draw.ellipse([W // 2 - ripple_r, 820 - ripple_r, W // 2 + ripple_r, 820 + ripple_r], outline=(200, 200, 212), width=2)
        draw_reticle(draw, W // 2, 820, radius=38, pulsing=1.0)
        draw.text((W // 2, 890), "STANDBY // READY TO GLIDE", font=f_mono, fill=(120, 120, 130), anchor="mm")

    return img


def render_scene_2(frame_idx: int) -> Image.Image:
    """Scene 2: Floating 3D MacBook Pro Reveal with Specular Glint (Frames 300 - 660, 12s)."""
    img = Image.new("RGB", (W, H), (255, 255, 255))
    draw = ImageDraw.Draw(img)
    draw_swiss_background(draw, frame_idx)

    f_title = ImageFont.truetype(FONT_HEADING, 76)
    f_body = ImageFont.truetype(FONT_SANS, 26)
    f_badge = ImageFont.truetype(FONT_HEADING, 20)
    f_mono = ImageFont.truetype(FONT_MONO, 20)

    # Left Column: Editorial Typography Stack
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

    # Floating 3D MacBook Pro with Camera Drift Physics
    drift_x = int(5.0 * math.sin(frame_idx * 0.04))
    drift_y = int(4.0 * math.cos(frame_idx * 0.04))
    mb_box = [840 + drift_x, 160 + drift_y, 1780 + drift_x, 890 + drift_y]

    raw_frame = load_cached_frame(FRAMES_HERO_DIR, frame_idx - 300)
    draw_macbook_bezel(img, raw_frame, mb_box)

    # Anamorphic Specular Sheen Glint across screen and aluminum bevel
    sheen_p = (frame_idx - 330) / 75.0
    draw_specular_sheen(img, mb_box, sheen_p)

    # Pixel Cursor Orb Floating Badge on Top-Right Corner
    orb_cx, orb_cy = 1730 + drift_x, 210 + drift_y
    draw.ellipse([orb_cx - 44, orb_cy - 44, orb_cx + 44, orb_cy + 44], fill=(10, 10, 12))
    draw.text((orb_cx, orb_cy), "ORB", font=f_badge, fill=(255, 255, 255), anchor="mm")
    draw_reticle(draw, orb_cx, orb_cy, radius=52, pulsing=1.0, color=(10, 10, 12))

    return img


def render_scene_3(frame_idx: int) -> Image.Image:
    """Scene 3: 21-Joint Biometric Skeleton Tracking & Tactile Shockwaves (Frames 660 - 1080, 14s)."""
    img = Image.new("RGB", (W, H), (255, 255, 255))
    draw = ImageDraw.Draw(img)
    draw_swiss_background(draw, frame_idx)

    f_stamp = ImageFont.truetype(FONT_HEADING, 52)
    f_sub = ImageFont.truetype(FONT_SANS, 24)
    f_mono = ImageFont.truetype(FONT_MONO, 20)
    f_badge = ImageFont.truetype(FONT_HEADING, 20)

    # Step Progression across 14 seconds
    rel_frame = frame_idx - 660
    if rel_frame < 140:
        step_num = "01 / POINT & GLIDE"
        step_desc = "Aim with your index finger to steer the macOS cursor."
    elif rel_frame < 280:
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
    is_pinching = 140 <= rel_frame < 280
    pinch_t = min(1.0, max(0.0, (rel_frame - 140) / 24.0)) if is_pinching else 0.0

    draw_hud_brackets(draw, [120, 360, 740, 680], color=(160, 160, 172))
    status_text = "STATUS: PINCH & DRAG LOCKED" if is_pinching else "STATUS: POINTING INDEX TIP"
    draw.text((160, 400), status_text, font=f_mono, fill=(10, 10, 12))
    draw.text((160, 445), f"COORDINATES: X={tx:04d} • Y={ty:04d} • Z=0.84", font=f_mono, fill=(80, 80, 90))
    draw.text((160, 490), "VISION ENGINE: 21 Landmarks @ 30 FPS", font=f_mono, fill=(80, 80, 90))
    draw.text((160, 535), "LATENCY BENCHMARK: < 5.8ms • 99.8% CONF", font=f_mono, fill=(80, 80, 90))
    draw.text((160, 580), "SMOOTHER: One-Euro Adaptive Cutoff Active", font=f_mono, fill=(80, 80, 90))

    pill_bg = (10, 10, 12) if is_pinching else (234, 234, 240)
    pill_fg = (255, 255, 255) if is_pinching else (10, 10, 12)
    draw_pill_badge(draw, "21-JOINT SKELETAL INFERENCE", 430, 635, f_badge, bg_color=pill_bg, text_color=pill_fg)

    # 21-Joint Biometric Hand Wireframe Overlay in Lower-Left Telemetry Area
    hand_ox = int(430 + 18 * math.sin(frame_idx * 0.06))
    hand_oy = int(870 + 12 * math.cos(frame_idx * 0.06))
    draw_skeletal_hand_21(draw, hand_ox, hand_oy, scale=1.15, pinch_t=pinch_t)

    # Right Column: Real Sandbox Footage with Camera Overlay
    raw_frame = load_cached_frame(FRAMES_SANDBOX_DIR, frame_idx - 660)
    mb_box = [820, 160, 1780, 890]
    draw_macbook_bezel(img, raw_frame, mb_box)

    # Dynamic HUD Crosshair Reticle tracking pointer
    draw_reticle(draw, tx, ty, radius=34 if is_pinching else 44, pulsing=0.88 if is_pinching else 1.0, color=(10, 10, 12))
    draw_hud_brackets(draw, [tx - 50, ty - 50, tx + 50, ty + 50], color=(10, 10, 12) if is_pinching else (120, 120, 130))

    # Expanding Tactile Shockwave on Pinch Lock
    if is_pinching:
        shock_p = ((rel_frame - 140) % 55) / 45.0
        draw_shockwave_ring(draw, tx, ty, shock_p, max_radius=115, color=(10, 10, 12))

    return img


def render_scene_4(frame_idx: int) -> Image.Image:
    """Scene 4: 18 Native Gestures Bento Grid & Parallax HUD (Frames 1080 - 1440, 12s)."""
    img = Image.new("RGB", (W, H), (255, 255, 255))
    draw = ImageDraw.Draw(img)
    draw_swiss_background(draw, frame_idx)

    f_title = ImageFont.truetype(FONT_HEADING, 54)
    f_sub = ImageFont.truetype(FONT_SANS, 22)
    f_mono = ImageFont.truetype(FONT_MONO, 18)
    f_badge = ImageFont.truetype(FONT_HEADING, 18)
    f_card_title = ImageFont.truetype(FONT_HEADING, 38)

    draw.text((W // 2, 130), "18 NATIVE MACOS GESTURES", font=f_title, fill=(10, 10, 12), anchor="mm")
    draw.text((W // 2, 175), "Hardware-level input synthesis with zero system extensions.", font=f_sub, fill=(90, 90, 100), anchor="mm")

    # Bento Card 1: Gestures Reference Table (x: 100 to 670)
    p_card1 = int(3.0 * math.sin(frame_idx * 0.05))
    draw.rounded_rectangle([100, 220 + p_card1, 670, 920 + p_card1], radius=16, fill=(250, 250, 252), outline=(224, 224, 232), width=1)
    draw_hud_brackets(draw, [100, 220 + p_card1, 670, 920 + p_card1], color=(180, 180, 190))
    draw.text((130, 260 + p_card1), "CORE GESTURE CATALOG", font=f_mono, fill=(10, 10, 12))

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
        gy = 315 + i * 80 + p_card1
        # Active status micro-indicator
        draw.ellipse([132, gy + 4, 140, gy + 12], fill=(40, 201, 64) if i in (0, 1, 3) else (180, 180, 190))
        draw.text((150, gy), g_name, font=f_mono, fill=(10, 10, 12))
        draw.text((150, gy + 28), g_desc, font=f_sub, fill=(100, 100, 112))

    # Bento Card 2: macOS Menu Bar Popover Frame (x: 700 to 1220)
    p_card2 = int(-3.0 * math.sin(frame_idx * 0.05))
    draw.rounded_rectangle([700, 220 + p_card2, 1220, 920 + p_card2], radius=16, fill=(250, 250, 252), outline=(224, 224, 232), width=1)
    draw_hud_brackets(draw, [700, 220 + p_card2, 1220, 920 + p_card2], color=(180, 180, 190))
    draw.text((730, 260 + p_card2), "MENU BAR CONTROLLER", font=f_mono, fill=(10, 10, 12))

    if os.path.exists(MENUBAR_POPOVER_PATH):
        popover_img = Image.open(MENUBAR_POPOVER_PATH).convert("RGB")
        pw = 420
        ph = int(pw * popover_img.height / popover_img.width)
        popover_resized = popover_img.resize((pw, ph), Image.Resampling.BILINEAR)
        img.paste(popover_resized, (750, 315 + p_card2))

    # Bento Card 3: 100% On-Device Privacy Architecture (x: 1250 to 1820)
    draw.rounded_rectangle([1250, 220, 1820, 920], radius=16, fill=(10, 10, 12))
    draw_hud_brackets(draw, [1250, 220, 1820, 920], color=(255, 255, 255))

    draw.text((1290, 275), "ZERO CLOUD DATA", font=f_card_title, fill=(255, 255, 255))
    draw.text((1290, 335), "100% ON-DEVICE PRIVACY", font=f_mono, fill=(180, 180, 190))

    privacy_points = [
        "In-memory processing via Apple Vision.",
        "Zero images or biometric data stored.",
        "Zero network calls. Operates 100% offline.",
        "Sandboxed macOS app architecture.",
        "Instant 1-click Emergency Pause trigger.",
    ]
    for i, pt in enumerate(privacy_points):
        py = 410 + i * 78
        draw_vector_check(draw, cx=1310, cy=py + 12, radius=11, badge_color=(255, 255, 255), check_color=(10, 10, 12), width=2)
        draw.text((1336, py), pt, font=f_sub, fill=(220, 220, 230))

    draw_pill_badge(draw, "VERIFIED SECURE", 1535, 845, f_badge, bg_color=(255, 255, 255), text_color=(10, 10, 12))

    return img


def render_scene_5(frame_idx: int) -> Image.Image:
    """Scene 5: Security Architecture & Settings Deep Dive (Frames 1440 - 1680, 8s)."""
    img = Image.new("RGB", (W, H), (255, 255, 255))
    draw = ImageDraw.Draw(img)
    draw_swiss_background(draw, frame_idx)

    f_title = ImageFont.truetype(FONT_HEADING, 54)
    f_sub = ImageFont.truetype(FONT_SANS, 22)
    f_mono = ImageFont.truetype(FONT_MONO, 18)
    f_badge = ImageFont.truetype(FONT_HEADING, 18)

    draw.text((W // 2, 130), "ENGINEERED FOR MACOS", font=f_title, fill=(10, 10, 12), anchor="mm")
    draw.text((W // 2, 175), "Zero background daemons. Apple Silicon native neural acceleration.", font=f_sub, fill=(90, 90, 100), anchor="mm")

    # Left Column: Security Architecture Bento (x: 100 to 780)
    draw.rounded_rectangle([100, 220, 780, 920], radius=16, fill=(250, 250, 252), outline=(224, 224, 232), width=1)
    draw_hud_brackets(draw, [100, 220, 780, 920], color=(180, 180, 190))
    draw.text((140, 265), "RUNTIME ARCHITECTURE SPECIFICATION", font=f_mono, fill=(10, 10, 12))

    specs = [
        ("FRAMEWORK PIPELINE", "AVCaptureSession -> VNDetectHumanHandPoseRequest"),
        ("NEURAL COPILOT", "Apple Neural Engine CoreML Hand Landmark Pipeline"),
        ("INFERENCE METRICS", "Rock-Solid 30 FPS • Under 3.2% CPU Load on M-Series"),
        ("MEMORY FOOTPRINT", "Under 45 MB Resident Memory • Zero Disk Cache"),
        ("INPUT SYNTHESIS", "CoreGraphics CGEventTap Hardware Emulation"),
        ("SAFETY GUARD", "Instant Fist Clench Emergency Pause Hardware Lock"),
    ]
    for i, (spec_title, spec_val) in enumerate(specs):
        sy = 325 + i * 85
        draw.text((140, sy), f"• {spec_title}", font=f_mono, fill=(10, 10, 12))
        draw.text((160, sy + 28), spec_val, font=f_sub, fill=(90, 90, 102))

    draw_pill_badge(draw, "100% OFFLINE ZERO-TELEMETRY", 440, 855, f_badge, bg_color=(10, 10, 12), text_color=(255, 255, 255))

    # Right Column: Sleek Floating Settings Window Frame (x: 820 to 1820)
    win_box = [820, 220, 1820, 920]
    draw.rounded_rectangle(win_box, radius=16, fill=(255, 255, 255), outline=(210, 210, 220), width=2)
    draw_hud_brackets(draw, win_box, color=(180, 180, 190))

    # Window Titlebar with Traffic Lights
    draw.rounded_rectangle([820, 220, 1820, 275], radius=16, fill=(245, 245, 248))
    draw.ellipse([845, 242, 859, 256], fill=(255, 95, 87))    # Red
    draw.ellipse([867, 242, 881, 256], fill=(254, 188, 46))   # Yellow
    draw.ellipse([889, 242, 903, 256], fill=(40, 201, 64))    # Green
    draw.text((1320, 248), "Swipy Settings — Motion Dynamics & Smoothing", font=f_mono, fill=(110, 110, 120), anchor="mm")

    # Paste Settings Screenshot inside frame
    if os.path.exists(CURSOR_SETTINGS_PATH):
        settings_img = Image.open(CURSOR_SETTINGS_PATH).convert("RGB")
        target_w = 960
        target_h = min(620, int(target_w * settings_img.height / settings_img.width))
        settings_resized = settings_img.resize((target_w, target_h), Image.Resampling.BILINEAR)
        img.paste(settings_resized, (840, 285))

    # Anamorphic specular glint across settings window glass
    sheen_p = (frame_idx - 1460) / 60.0
    draw_specular_sheen(img, win_box, sheen_p)

    return img


def render_scene_6(frame_idx: int) -> Image.Image:
    """Scene 6: Commercial Finale & Pulsing Invitation (Frames 1680 - 1920, 8s)."""
    img = Image.new("RGB", (W, H), (255, 255, 255))
    draw = ImageDraw.Draw(img)
    draw_swiss_background(draw, frame_idx)

    f_huge = ImageFont.truetype(FONT_HEADING, 76)
    f_sub = ImageFont.truetype(FONT_SANS, 32)
    f_cta = ImageFont.truetype(FONT_HEADING, 28)
    f_mono = ImageFont.truetype(FONT_MONO, 24)

    # 1. Swipy App Logo at Top-Center with Elevation Shadow
    if os.path.exists(LOGO_PATH):
        logo = Image.open(LOGO_PATH).convert("RGBA")
        logo_size = 110
        logo_resized = logo.resize((logo_size, logo_size), Image.Resampling.BILINEAR)
        lx, ly = (W - logo_size) // 2, 200
        draw.rounded_rectangle([lx - 4, ly + 6, lx + logo_size + 4, ly + logo_size + 14], radius=24, fill=(224, 224, 232))
        img.paste(logo_resized, (lx, ly), logo_resized)

    # 2. Hero Closing Slogan
    draw.text((W // 2, 380), "CONTROL YOUR MAC.", font=f_huge, fill=(10, 10, 12), anchor="mm")

    # Inverted Black Pill Badge for Tagline
    draw_pill_badge(draw, "WITH A WAVE OF YOUR HAND.", W // 2, 480, f_huge, bg_color=(10, 10, 12), text_color=(255, 255, 255), pad_x=36, pad_y=16)

    draw.text((W // 2, 590), "Touchless spatial hand control for macOS. Works with your built-in camera.", font=f_sub, fill=(90, 90, 100), anchor="mm")

    # 3. Primary CTA: Download macOS DMG Button with Pulsing Wavefield
    pulse_r = int(((frame_idx - 1680) * 4) % 65)
    btn_w, btn_h = 440, 70
    bx0, by0 = (W - btn_w) // 2, 665
    bx1, by1 = bx0 + btn_w, by0 + btn_h

    # Expanding concentric halo pulse
    if pulse_r > 5:
        draw.rounded_rectangle([bx0 - pulse_r, by0 - pulse_r, bx1 + pulse_r, by1 + pulse_r], radius=35 + pulse_r // 2, outline=(215, 215, 225), width=2)

    draw_pill_badge(draw, "DOWNLOAD MACOS DMG", W // 2, 700, f_cta, bg_color=(10, 10, 12), text_color=(255, 255, 255), pad_x=44, pad_y=18)
    draw_hud_brackets(draw, [bx0 - 35, by0 - 15, bx1 + 35, by1 + 15], color=(10, 10, 12), tick_len=24, width=3)

    # 4. Web Portal & GitHub Badges
    draw.text((W // 2, 810), "WEBSITE: GETSWIPY.VERCEL.APP", font=f_mono, fill=(10, 10, 12), anchor="mm")
    draw.text((W // 2, 860), "GITHUB: DARKNECROCITIES / SWIPY", font=f_mono, fill=(110, 110, 120), anchor="mm")

    # Optical smooth fade to pure white on the final 18 frames
    if frame_idx >= 1902:
        p_fade = (frame_idx - 1902) / 18.0
        overlay = Image.new("RGB", (W, H), (255, 255, 255))
        img = Image.blend(img, overlay, p_fade)

    return img
