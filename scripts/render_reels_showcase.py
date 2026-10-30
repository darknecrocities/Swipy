#!/usr/bin/env python3
"""Programmatic Video Renderer for Swipy Facebook Reels Showcase Film.

Renders 960 frames (1080x1920, 30 FPS, 32.0s) directly into FFmpeg stdin.
Choreographs 5 scenes, real user demo footage, Swiss kinetic typography,
word & shape morphing, slice curtain zebra wipes, symmetrical mirror splits,
and HUD tracking reticles.

Strictly complies with SkillBuilder cognitive limits (<500 lines).
"""

import math
import os
import subprocess
import numpy as np
from PIL import Image, ImageDraw, ImageFont

from reels_effects import (
    W, H, FONT_HEADING, FONT_SANS, FONT_MONO,
    draw_swiss_background, draw_hud_brackets, draw_reticle,
    apply_slice_curtain, apply_symmetrical_split, apply_iris_wipe,
    draw_macbook_bezel, ease_snap, ease_smooth
)
from reels_scenes import render_scene_1, render_scene_2

FPS = 30
TOTAL_FRAMES = 960
AUDIO_MASTER_WAV = "assets/showcase-video/reels_audio_master.wav"
OUTPUT_MP4 = "assets/showcase-video/swipy-touchless-reels.mp4"

SCRATCH_DIR = "/Users/arronkianparejas/.gemini/antigravity/brain/44f6a692-c641-4a23-bd30-b5abab155805/scratch"
FRAMES_HERO_DIR = os.path.join(SCRATCH_DIR, "frames_hero")
FRAMES_SANDBOX_DIR = os.path.join(SCRATCH_DIR, "frames_sandbox")
FRAMES_WORKSTATION_DIR = os.path.join(SCRATCH_DIR, "frames_workstation")

LOGO_PATH = "Resources/AppLogo.png"


def load_clip_frame(folder: str, idx: int) -> Image.Image:
    """Safely load cached frame image from scratch directory."""
    files = sorted(os.listdir(folder))
    clamped_idx = max(0, min(len(files) - 1, idx))
    path = os.path.join(folder, files[clamped_idx])
    return Image.open(path).convert("RGB")


def render_scene_3(frame_idx: int) -> Image.Image:
    """Scene 3: Live Hand Vision & Cursor Pinch Tracking (Frames 360 - 600)."""
    img = Image.new("RGB", (W, H), (0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_swiss_background(draw, frame_idx)

    f_stamp = ImageFont.truetype(FONT_HEADING, 76)
    f_sub = ImageFont.truetype(FONT_SANS, 32)
    f_mono = ImageFont.truetype(FONT_MONO, 24)

    # Top Kinetic Stamp by Downbeat
    if frame_idx < 440:
        draw.text((W // 2, 220), "01 / POINT & GLIDE", font=f_stamp, fill=(255, 255, 255), anchor="mm")
        draw.text((W // 2, 290), "Aim with your index finger across the screen", font=f_sub, fill=(180, 180, 180), anchor="mm")
    elif frame_idx < 520:
        draw.text((W // 2, 220), "02 / PINCH TO GRAB", font=f_stamp, fill=(255, 255, 255), anchor="mm")
        draw.text((W // 2, 290), "Touch thumb & index together to lock onto windows", font=f_sub, fill=(180, 180, 180), anchor="mm")
    else:
        draw.text((W // 2, 220), "03 / DRAG ANYWHERE", font=f_stamp, fill=(255, 255, 255), anchor="mm")
        draw.text((W // 2, 290), "1:1 fluid window positioning across multi-monitors", font=f_sub, fill=(180, 180, 180), anchor="mm")

    # Center: Real Footage of User in Sandbox with Webcam PiP
    clip_idx = frame_idx - 360
    raw_frame = load_clip_frame(FRAMES_SANDBOX_DIR, clip_idx)
    sandbox_box = [60, 370, W - 60, 980]
    draw_macbook_bezel(img, raw_frame, sandbox_box)

    # Dynamic HUD Target Tracking Reticle Overlays
    tx = int(540 + 160 * math.sin(frame_idx * 0.08))
    ty = int(680 + 100 * math.cos(frame_idx * 0.08))
    is_pinching = 440 <= frame_idx < 520
    draw_reticle(draw, tx, ty, radius=36 if is_pinching else 48, pulsing=0.85 if is_pinching else 1.0)
    draw_hud_brackets(draw, [tx - 64, ty - 64, tx + 64, ty + 64], color=(255, 255, 255) if is_pinching else (120, 120, 120))

    # Bottom Coordinate & Gesture Readout
    draw_hud_brackets(draw, [60, 1050, W - 60, 1420], color=(80, 80, 80))
    action_text = "STATUS: PINCH & DRAG LOCKED" if is_pinching else "STATUS: POINTING INDEX TIP"
    draw.text((100, 1100), action_text, font=f_mono, fill=(255, 255, 255))
    draw.text((100, 1145), f"COORDINATES: X={tx:04d} • Y={ty:04d} • Z=0.82 (DEPTH LOCKED)", font=f_mono, fill=(180, 180, 180))
    draw.text((100, 1195), "Apple Vision landmark model locks on 21 finger joints at 30 FPS.", font=f_sub, fill=(160, 160, 160))
    draw.text((100, 1245), "One-Euro Filter eliminates natural hand micro-jitters.", font=f_sub, fill=(140, 140, 140))

    # Gesture Pill indicator
    draw.rounded_rectangle([100, 1310, 480, 1366], radius=28, fill=(255, 255, 255))
    draw.text((290, 1338), "INDEX & THUMB TRACKING", font=f_mono, fill=(0, 0, 0), anchor="mm")

    return img


def render_scene_4(frame_idx: int) -> Image.Image:
    """Scene 4: 15 Native macOS Gestures & On-Device Security (Frames 600 - 810)."""
    img = Image.new("RGB", (W, H), (0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_swiss_background(draw, frame_idx)

    f_title = ImageFont.truetype(FONT_HEADING, 76)
    f_sub = ImageFont.truetype(FONT_SANS, 34)
    f_mono = ImageFont.truetype(FONT_MONO, 24)

    # Top Header
    draw.text((W // 2, 220), "15 NATIVE GESTURES.", font=f_title, fill=(255, 255, 255), anchor="mm")
    draw.text((W // 2, 290), "Control everything without touching glass", font=f_sub, fill=(180, 180, 180), anchor="mm")

    # Center: Real Footage of Workstation & Skeleton Tracking Feed
    clip_idx = frame_idx - 600
    raw_frame = load_clip_frame(FRAMES_WORKSTATION_DIR, clip_idx)
    work_box = [60, 360, W - 60, 970]
    draw_macbook_bezel(img, raw_frame, work_box)

    # Gesture Cards Staggered on Downbeats
    gestures = [
        ("4-FINGER SWIPE", "Instant macOS Space Navigation", 610),
        ("PINCH & DRAG", "1:1 Window & Item Manipulation", 650),
        ("3-FINGER SWIPE", "Mission Control & App Switcher", 690),
        ("OPEN PALMS HOLD", "Instant Emergency Motion Pause", 730),
    ]

    card_y = 1040
    for name, desc, trigger_frame in gestures:
        if frame_idx >= trigger_frame:
            p = ease_snap(min(1.0, (frame_idx - trigger_frame) / 12.0))
            offset_x = int((1.0 - p) * 120)
            draw.rounded_rectangle([80 + offset_x, card_y, W - 80, card_y + 64], radius=14, fill=(22, 22, 22), outline=(60, 60, 60))
            draw.text((110 + offset_x, card_y + 32), name, font=f_mono, fill=(255, 255, 255), anchor="lm")
            draw.text((W - 120, card_y + 32), desc, font=f_mono, fill=(150, 150, 150), anchor="rm")
        card_y += 78

    # Privacy Guarantee Badge
    draw.rounded_rectangle([80, 1380, W - 80, 1450], radius=16, fill=(255, 255, 255))
    draw.text((W // 2, 1415), "100% ON-DEVICE PRIVACY • ZERO CAMERA VIDEO SAVED", font=f_mono, fill=(0, 0, 0), anchor="mm")

    return img


def render_scene_5(frame_idx: int) -> Image.Image:
    """Scene 5: Call to Action, Swipy Orb Morph & Outro (Frames 810 - 960)."""
    img = Image.new("RGB", (W, H), (0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_swiss_background(draw, frame_idx)

    f_huge = ImageFont.truetype(FONT_HEADING, 76)
    f_large = ImageFont.truetype(FONT_HEADING, 62)
    f_sub = ImageFont.truetype(FONT_SANS, 34)
    f_mono = ImageFont.truetype(FONT_MONO, 28)

    # Fade out in last 15 frames
    fade = 1.0
    if frame_idx >= 945:
        fade = max(0.0, (960 - frame_idx) / 15.0)

    # Top Brand Mark
    if os.path.exists(LOGO_PATH):
        logo = Image.open(LOGO_PATH).convert("RGBA").resize((110, 110))
        img.paste(logo, (W // 2 - 55, 320), logo)

    # Dot-Matrix Reticle Rotating Hand Orb (Shape Morph)
    orb_center = (W // 2, 600)
    rot_angle = (frame_idx - 810) * 0.05
    for r in range(40, 180, 24):
        n_dots = int(2 * math.pi * r / 20)
        for d in range(n_dots):
            theta = d * (2 * math.pi / n_dots) + rot_angle * (1.0 if r % 48 == 0 else -1.0)
            dx = int(orb_center[0] + r * math.cos(theta))
            dy = int(orb_center[1] + r * math.sin(theta))
            draw.rectangle([dx - 2, dy - 2, dx + 2, dy + 2], fill=(200, 200, 200))

    draw_reticle(draw, orb_center[0], orb_center[1], radius=72, pulsing=1.0)

    # Main CTA Typography
    draw.text((W // 2, 880), "CONTROL YOUR MAC", font=f_huge, fill=(255, 255, 255), anchor="mm")
    draw.text((W // 2, 970), "WITH A WAVE OF YOUR HAND.", font=f_large, fill=(200, 200, 200), anchor="mm")
    draw.text((W // 2, 1070), "Turn your MacBook camera into a spatial trackpad.", font=f_sub, fill=(160, 160, 160), anchor="mm")

    # High Contrast White CTA Pill Button
    f_cta = ImageFont.truetype(FONT_HEADING, 56)
    draw.rounded_rectangle([W // 2 - 420, 1160, W // 2 + 420, 1280], radius=60, fill=(255, 255, 255))
    draw.text((W // 2, 1220), "DOWNLOAD FOR MAC", font=f_cta, fill=(0, 0, 0), anchor="mm")

    # Badges
    draw_hud_brackets(draw, [W // 2 - 450, 1130, W // 2 + 450, 1310], color=(140, 140, 140), tick_len=24, width=3)
    draw.text((W // 2, 1370), "[ FREE • OPEN SOURCE • MACOS 14.0+ ]", font=f_mono, fill=(220, 220, 220), anchor="mm")
    draw.text((W // 2, 1460), "GETSWIPY.VERCEL.APP", font=f_mono, fill=(255, 255, 255), anchor="mm")

    # Apply fade out if ending
    if fade < 1.0:
        black = Image.new("RGB", (W, H), (0, 0, 0))
        img = Image.blend(black, img, fade)

    return img


def generate_frame(frame_idx: int) -> np.ndarray:
    """Compose full frame with kinetic transitions across all 5 scenes."""
    # Scene boundaries: 0-150, 150-360, 360-600, 600-810, 810-960
    TRANS_LEN = 15  # 15 frames = 0.5s downbeat wipe

    # Scene 1 -> 2: Slice Curtain (Frames 135 to 150)
    if 135 <= frame_idx < 150:
        s1 = render_scene_1(frame_idx)
        s2 = render_scene_2(150)
        p = (frame_idx - 135) / TRANS_LEN
        frame_img = apply_slice_curtain(s1, s2, p, num_slices=12)

    # Scene 2 (Frames 150 to 345)
    elif 150 <= frame_idx < 345:
        frame_img = render_scene_2(frame_idx)

    # Scene 2 -> 3: Symmetrical Center Split (Frames 345 to 360)
    elif 345 <= frame_idx < 360:
        s2 = render_scene_2(frame_idx)
        s3 = render_scene_3(360)
        p = (frame_idx - 345) / TRANS_LEN
        frame_img = apply_symmetrical_split(s2, s3, p)

    # Scene 3 (Frames 360 to 585)
    elif 360 <= frame_idx < 585:
        frame_img = render_scene_3(frame_idx)

    # Scene 3 -> 4: Slice Curtain (Frames 585 to 600)
    elif 585 <= frame_idx < 600:
        s3 = render_scene_3(frame_idx)
        s4 = render_scene_4(600)
        p = (frame_idx - 585) / TRANS_LEN
        frame_img = apply_slice_curtain(s3, s4, p, num_slices=14)

    # Scene 4 (Frames 600 to 795)
    elif 600 <= frame_idx < 795:
        frame_img = render_scene_4(frame_idx)

    # Scene 4 -> 5: Circular Iris Wipe (Frames 795 to 810)
    elif 795 <= frame_idx < 810:
        s4 = render_scene_4(frame_idx)
        s5 = render_scene_5(810)
        p = (frame_idx - 795) / TRANS_LEN
        frame_img = apply_iris_wipe(s4, s5, p)

    # Scene 5 (Frames 810 to 960)
    elif frame_idx >= 810:
        frame_img = render_scene_5(frame_idx)

    # Scene 1 default
    else:
        frame_img = render_scene_1(frame_idx)

    return np.array(frame_img, dtype=np.uint8)


def main():
    """Main rendering loop streaming raw video directly into FFmpeg stdin."""
    print("🎬 Initializing Swipy Reels Video Pipeline...")
    os.makedirs(os.path.dirname(OUTPUT_MP4), exist_ok=True)

    ffmpeg_cmd = [
        "ffmpeg", "-y",
        "-f", "rawvideo",
        "-vcodec", "rawvideo",
        "-s", f"{W}x{H}",
        "-pix_fmt", "rgb24",
        "-r", str(FPS),
        "-i", "-",               # Video pipe from stdin
        "-i", AUDIO_MASTER_WAV,  # Master soundtrack
        "-c:v", "libx264",
        "-preset", "medium",
        "-crf", "16",            # Pristine vector typography quality
        "-pix_fmt", "yuv420p",   # Web & mobile Reels compatibility
        "-c:a", "aac",
        "-b:a", "320k",
        "-shortest",
        OUTPUT_MP4
    ]

    print(f"🚀 Spawning FFmpeg stdin pipe: {W}x{H} @ {FPS} FPS...")
    proc = subprocess.Popen(
        ffmpeg_cmd,
        stdin=subprocess.PIPE,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.PIPE
    )

    print(f"🎨 Rendering {TOTAL_FRAMES} frames...")
    for idx in range(TOTAL_FRAMES):
        frame_rgb = generate_frame(idx)
        proc.stdin.write(frame_rgb.tobytes())

        if (idx + 1) % 120 == 0 or idx == TOTAL_FRAMES - 1:
            progress = (idx + 1) / TOTAL_FRAMES * 100.0
            print(f"  Frame {idx + 1:03d} / {TOTAL_FRAMES} ({progress:.1f}%)")

    proc.stdin.close()
    stderr_output = proc.stderr.read()
    proc.wait()

    if proc.returncode != 0:
        print("❌ FFmpeg encoding failed:\n", stderr_output.decode("utf-8"))
        exit(1)

    print(f"🎉 Master film rendered successfully: {OUTPUT_MP4}")


if __name__ == "__main__":
    main()
