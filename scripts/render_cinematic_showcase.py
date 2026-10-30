#!/usr/bin/env python3
"""Programmatic Master Renderer for Swipy 1080p Landscape Showcase Film.

Pipes 1920 raw RGB24 frames (1920x1080 @ 30 FPS, 64.0s) directly into FFmpeg stdin.
Choreographs 6 cinematic scenes, real MacBook Pro demo footage, Swiss kinetic
typography, shape morphing, slice curtain zebra wipes, symmetrical mirror splits,
and HUD tracking reticles locked to a 120 BPM tempo grid.

Strictly complies with SkillBuilder cognitive limits (<500 lines).
"""

import json
import os
import subprocess
import time
from PIL import Image

from cinematic_effects import (
    W, H,
    apply_slice_curtain, apply_symmetrical_split, apply_iris_wipe
)
from cinematic_scenes import (
    render_scene_1, render_scene_2, render_scene_3,
    render_scene_4, render_scene_5, render_scene_6
)

OUTPUT_DIR = "assets/showcase-video"
PREVIEWS_DIR = os.path.join(OUTPUT_DIR, "previews")
OUTPUT_MP4 = os.path.join(OUTPUT_DIR, "swipy-cinematic-showcase.mp4")
AUDIO_MASTER_WAV = os.path.join(OUTPUT_DIR, "cinematic_audio_master.wav")
TIMELINE_JSON = os.path.join(OUTPUT_DIR, "showcase_timeline.json")

ARTIFACT_DIR = "/Users/arronkianparejas/.gemini/antigravity/brain/44f6a692-c641-4a23-bd30-b5abab155805"


def get_scene_function(scene_idx: int):
    """Map 1-based scene index to renderer function."""
    funcs = {
        1: render_scene_1,
        2: render_scene_2,
        3: render_scene_3,
        4: render_scene_4,
        5: render_scene_5,
        6: render_scene_6,
    }
    return funcs.get(scene_idx, render_scene_6)


def apply_transition(sc_idx: int, cur_img: Image.Image, next_img: Image.Image, p: float) -> Image.Image:
    """Apply distinct beat-locked transition filter between scenes."""
    if sc_idx == 1:
        return apply_slice_curtain(cur_img, next_img, p, num_slices=12)
    elif sc_idx == 2:
        return apply_symmetrical_split(cur_img, next_img, p)
    elif sc_idx == 3:
        return apply_iris_wipe(cur_img, next_img, p)
    elif sc_idx == 4:
        return apply_symmetrical_split(cur_img, next_img, p)
    elif sc_idx == 5:
        return apply_slice_curtain(cur_img, next_img, p, num_slices=16)
    return next_img


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    os.makedirs(PREVIEWS_DIR, exist_ok=True)
    os.makedirs(os.path.join(ARTIFACT_DIR, "cinematic_preview"), exist_ok=True)

    if not os.path.exists(TIMELINE_JSON):
        raise FileNotFoundError(f"Timeline JSON missing: {TIMELINE_JSON}. Run audio_cinematic_producer.py first.")
    if not os.path.exists(AUDIO_MASTER_WAV):
        raise FileNotFoundError(f"Audio master missing: {AUDIO_MASTER_WAV}.")

    with open(TIMELINE_JSON, "r") as f:
        timeline = json.load(f)

    total_frames = timeline["total_frames"]
    scenes = timeline["scenes"]
    print(f"🎬 Starting Cinematic Landscape Film Rendering (1920x1080, {total_frames} frames, 30 FPS)...")

    # Start FFmpeg Subprocess Pipe
    cmd = [
        "ffmpeg", "-y",
        "-f", "rawvideo",
        "-vcodec", "rawvideo",
        "-s", f"{W}x{H}",
        "-pix_fmt", "rgb24",
        "-r", "30",
        "-i", "-",  # stdin pipe
        "-i", AUDIO_MASTER_WAV,
        "-c:v", "libx264",
        "-preset", "medium",
        "-crf", "17",
        "-pix_fmt", "yuv420p",
        "-c:a", "aac",
        "-b:a", "320k",
        "-shortest",
        OUTPUT_MP4
    ]
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stderr=subprocess.DEVNULL)

    preview_snapshots = {
        140: "scene1_hook.png",
        480: "scene2_reveal.png",
        870: "scene3_precision.png",
        1260: "scene4_gestures.png",
        1560: "scene5_architecture.png",
        1800: "scene6_cta.png"
    }

    t0 = time.time()
    for frame_idx in range(total_frames):
        # Locate current active scene
        cur_scene = None
        for sc in scenes:
            if sc["start_frame"] <= frame_idx < sc["end_frame"]:
                cur_scene = sc
                break
        if cur_scene is None:
            cur_scene = scenes[-1]

        sc_idx = cur_scene["scene_idx"]
        cur_func = get_scene_function(sc_idx)

        # Check if frame falls within transition window
        is_trans = (
            frame_idx >= cur_scene["trans_start_frame"] and
            sc_idx < len(scenes)
        )

        if is_trans:
            trans_dur = cur_scene["end_frame"] - cur_scene["trans_start_frame"]
            p = (frame_idx - cur_scene["trans_start_frame"]) / max(1.0, float(trans_dur))
            cur_img = cur_func(frame_idx)
            next_func = get_scene_function(sc_idx + 1)
            next_img = next_func(frame_idx)
            final_frame = apply_transition(sc_idx, cur_img, next_img, p)
        else:
            final_frame = cur_func(frame_idx)

        # Write frame to FFmpeg stdin
        proc.stdin.write(final_frame.tobytes())

        # Save visual preview snapshots
        if frame_idx in preview_snapshots:
            snap_name = preview_snapshots[frame_idx]
            local_snap_path = os.path.join(PREVIEWS_DIR, snap_name)
            art_snap_path = os.path.join(ARTIFACT_DIR, "cinematic_preview", snap_name)
            final_frame.save(local_snap_path)
            final_frame.save(art_snap_path)
            print(f"  📸 Exported Preview Snapshot: {snap_name} (Frame {frame_idx})")

        if frame_idx % 200 == 0 or frame_idx == total_frames - 1:
            elapsed = time.time() - t0
            fps_speed = (frame_idx + 1) / max(0.001, elapsed)
            percent = (frame_idx + 1) / total_frames * 100.0
            print(f"  ⏳ Rendered {frame_idx + 1}/{total_frames} frames ({percent:.1f}%) • {fps_speed:.1f} FPS")

    proc.stdin.close()
    proc.wait()

    total_time = time.time() - t0
    file_size_mb = os.path.getsize(OUTPUT_MP4) / (1024 * 1024)
    print(f"✨ Production Film Completed in {total_time:.1f}s!")
    print(f"📦 Master Film: {OUTPUT_MP4} ({file_size_mb:.2f} MB, 1080p Landscape, 30 FPS, CRF 17)")


if __name__ == "__main__":
    main()
