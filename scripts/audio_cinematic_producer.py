#!/usr/bin/env python3
"""Cinematic Broadcast Audio Producer for Swipy Landscape Showcase Film.

Synthesizes:
1. Emotive neural TTS male voiceover (en-US-AndrewMultilingualNeural via edge-tts).
2. Broadcast vocal dynamics chain (90Hz HPF, 3.2kHz presence EQ lift, LA-2A compressor).
3. Dynamic stem measurement & 120 BPM beat-locked chapter timeline JSON.
4. Synchronized 120 BPM rhythmic tech music bed (kick, snare, hi-hats, 808 sub-bass pulse).
5. Synchronized SFX (sub-bass impacts, whoosh transition sweeps, HUD chirps, pinch clicks).
6. Sidechain ducking (-6.5dB during dialogue) exporting 48kHz stereo master WAV.

Strictly complies with SkillBuilder cognitive limits (<500 lines).
"""

import asyncio
import json
import os
import subprocess
import wave
import numpy as np
import edge_tts

SR = 48000
BPM = 120.0
BEAT_SEC = 60.0 / BPM  # 0.5s (15 frames at 30 FPS)
BAR_SEC = BEAT_SEC * 4.0  # 2.0s (60 frames at 30 FPS)

SCRATCH_DIR = "/Users/arronkianparejas/.gemini/antigravity/brain/44f6a692-c641-4a23-bd30-b5abab155805/scratch"
OUTPUT_DIR = "assets/showcase-video"
AUDIO_MASTER_WAV = os.path.join(OUTPUT_DIR, "cinematic_audio_master.wav")
TIMELINE_JSON = os.path.join(OUTPUT_DIR, "showcase_timeline.json")

SCRIPT_LINES = [
    {
        "id": "scene_01_hook",
        "title": "Hook & Touchless Morph",
        "text": "What if the new M6 MacBook was touchscreen? But wait... what if you didn't even have to touch the screen?",
    },
    {
        "id": "scene_02_reveal",
        "title": "Product Hero Reveal",
        "text": "Meet Swipy. It turns your built-in MacBook camera into a natural spatial trackpad.",
    },
    {
        "id": "scene_03_precision",
        "title": "Vision & Cursor Precision",
        "text": "Glide your index finger to steer the cursor. Pinch thumb and index to grab and drag windows across displays.",
    },
    {
        "id": "scene_04_gestures",
        "title": "18 Gestures & Security",
        "text": "Flick four fingers to switch Spaces. 18 native gestures, powered by 21-point Apple Vision entirely on-device.",
    },
    {
        "id": "scene_05_cta",
        "title": "Marketable Finale & CTA",
        "text": "Control your Mac with a wave of your hand. Download Swipy today for macOS.",
    },
]


def load_wav_mono(path: str) -> np.ndarray:
    """Read uncompressed WAV file as float32 numpy array."""
    with wave.open(path, "rb") as wf:
        n_frames = wf.getnframes()
        data = wf.readframes(n_frames)
        samples = np.frombuffer(data, dtype=np.int16).astype(np.float32) / 32768.0
        return samples


async def synthesize_and_measure():
    """Synthesize voiceover lines, measure durations, and lock to 120 BPM downbeats."""
    os.makedirs(SCRATCH_DIR, exist_ok=True)
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print("🎙️ Synthesizing emotive neural voiceover (en-US-AndrewMultilingualNeural)...")

    stem_data = []
    for item in SCRIPT_LINES:
        raw_mp3 = os.path.join(SCRATCH_DIR, f"{item['id']}_raw.mp3")
        clean_wav = os.path.join(SCRATCH_DIR, f"{item['id']}_clean.wav")

        communicate = edge_tts.Communicate(item["text"], "en-US-AndrewMultilingualNeural", rate="+3%")
        await communicate.save(raw_mp3)

        # Broadcast vocal dynamics filter chain
        filter_str = (
            "silenceremove=start_periods=1:start_duration=0.01:start_threshold=-42dB:"
            "stop_periods=-1:stop_duration=0.15:stop_threshold=-42dB,"
            "highpass=f=90,"
            "equalizer=f=3200:t=q:w=1.2:g=2.8,"
            "acompressor=threshold=-16dB:ratio=3.2:attack=8:release=80,"
            "volume=1.28"
        )
        cmd = [
            "ffmpeg", "-y", "-i", raw_mp3,
            "-af", filter_str,
            "-ar", str(SR), "-ac", "1",
            clean_wav
        ]
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

        samples = load_wav_mono(clean_wav)
        dur = len(samples) / SR
        stem_data.append({
            "id": item["id"],
            "title": item["title"],
            "text": item["text"],
            "wav_path": clean_wav,
            "samples": samples,
            "dur": dur,
        })
        print(f"  ✓ Processed: {item['id']} ({dur:.2f}s)")

    # Build Beat-Locked Timeline
    timeline = {"fps": 30, "bpm": BPM, "scenes": []}
    current_sec = 0.0

    for idx, stem in enumerate(stem_data):
        scene_start_sec = current_sec
        # Voice begins 0.4s (or 0.5s downbeat) after scene opens
        vo_start_sec = scene_start_sec + 0.45
        vo_end_sec = vo_start_sec + stem["dur"]
        
        # Enforce >= 0.85s silence cushion after voiceover ends
        min_scene_end = vo_end_sec + 0.85
        # Snap scene end to the next musical bar boundary (multiples of 2.0s)
        bars = int(np.ceil(min_scene_end / BAR_SEC))
        scene_end_sec = float(bars * BAR_SEC)
        # Ensure at least 3 bars (6.0s) per scene for visual breathing room
        if scene_end_sec - scene_start_sec < 6.0:
            scene_end_sec = scene_start_sec + 6.0

        scene_start_frame = int(round(scene_start_sec * 30))
        scene_end_frame = int(round(scene_end_sec * 30))
        trans_start_frame = max(scene_start_frame, scene_end_frame - 15)  # 15 frames (0.5s) transition

        scene_info = {
            "scene_idx": idx + 1,
            "id": stem["id"],
            "title": stem["title"],
            "text": stem["text"],
            "start_sec": scene_start_sec,
            "end_sec": scene_end_sec,
            "dur_sec": scene_end_sec - scene_start_sec,
            "vo_start_sec": vo_start_sec,
            "vo_end_sec": vo_end_sec,
            "start_frame": scene_start_frame,
            "end_frame": scene_end_frame,
            "trans_start_frame": trans_start_frame,
            "wav_path": stem["wav_path"]
        }
        timeline["scenes"].append(scene_info)
        current_sec = scene_end_sec

    # Extra 1.0s tail resolving musical cadence
    total_dur_sec = current_sec + 1.0
    timeline["total_dur_sec"] = total_dur_sec
    timeline["total_frames"] = int(round(total_dur_sec * 30))

    with open(TIMELINE_JSON, "w") as f:
        json.dump(timeline, f, indent=2)
    print(f"📋 Timeline exported: {TIMELINE_JSON} ({timeline['total_dur_sec']:.1f}s, {timeline['total_frames']} frames)")

    return timeline, stem_data


def synth_music_bed(total_samples: int) -> np.ndarray:
    """Synthesize 120 BPM punchy tech music bed with kick, snare, hats, and 808 sub."""
    music = np.zeros(total_samples, dtype=np.float32)
    total_beats = int(total_samples / (BEAT_SEC * SR))

    for beat in range(total_beats):
        beat_start = int(beat * BEAT_SEC * SR)
        beat_idx = beat % 4

        # 1. Solid Acoustic/Electronic Kick on Beats 0 & 2
        if beat_idx in (0, 2):
            k_len = int(0.24 * SR)
            k_t = np.arange(k_len) / SR
            k_freq = 145.0 * np.exp(-k_t * 20.0) + 46.0
            k_phase = 2.0 * np.pi * np.cumsum(k_freq) / SR
            k_env = np.exp(-k_t * 15.0)
            kick = 0.54 * np.sin(k_phase) * k_env
            end = min(total_samples, beat_start + k_len)
            music[beat_start:end] += kick[:end - beat_start]

        # 2. Snare Drum on Beats 1 & 3
        if beat_idx in (1, 3):
            s_len = int(0.20 * SR)
            s_t = np.arange(s_len) / SR
            s_body = 0.22 * np.sin(2.0 * np.pi * 190.0 * s_t) * np.exp(-s_t * 24.0)
            s_noise = 0.26 * (np.random.rand(s_len) * 2.0 - 1.0) * np.exp(-s_t * 28.0)
            snare = s_body + s_noise
            end = min(total_samples, beat_start + s_len)
            music[beat_start:end] += snare[:end - beat_start]

        # 3. Tight Hi-Hats on 8th and 16th notes
        for sub_beat in (0.0, 0.25, 0.5, 0.75):
            h_start = int((beat + sub_beat) * BEAT_SEC * SR)
            h_len = int(0.038 * SR)
            h_t = np.arange(h_len) / SR
            h_noise = (np.random.rand(h_len) * 2.0 - 1.0) * np.exp(-h_t * 110.0)
            vol = 0.10 if sub_beat in (0.0, 0.5) else 0.05
            h_val = vol * h_noise
            end = min(total_samples, h_start + h_len)
            if h_start < total_samples:
                music[h_start:end] += h_val[:end - h_start]

    # 4. Melodic 808 Sub-Bass Pulse (Key of A minor: A, G, E, F)
    bass_notes = [55.0, 48.99, 41.20, 43.65]
    total_bars = int(total_samples / (BAR_SEC * SR))
    for bar in range(total_bars):
        bar_start = int(bar * BAR_SEC * SR)
        b_freq = bass_notes[bar % len(bass_notes)]
        b_len = int(1.8 * SR)
        b_t = np.arange(b_len) / SR
        b_pulse = 0.24 * np.sin(2.0 * np.pi * b_freq * b_t) * np.exp(-b_t * 1.6)
        b_pulse += 0.07 * np.sin(2.0 * np.pi * (b_freq * 2) * b_t) * np.exp(-b_t * 2.8)
        end = min(total_samples, bar_start + b_len)
        if bar_start < total_samples:
            music[bar_start:end] += b_pulse[:end - bar_start]

    return music


def build_sfx(timeline: dict, total_samples: int) -> np.ndarray:
    """Synthesize synchronized whoosh sweeps, sub impacts, and tactile clicks."""
    sfx = np.zeros(total_samples, dtype=np.float32)

    def add_sub_impact(sec: float):
        start = int(sec * SR)
        dur = int(1.2 * SR)
        t = np.arange(dur) / SR
        wave_sub = 0.44 * np.sin(2.0 * np.pi * 54.0 * np.exp(-t * 2.8) * t) * np.exp(-t * 2.6)
        end = min(total_samples, start + dur)
        if start < total_samples:
            sfx[start:end] += wave_sub[:end - start]

    def add_whoosh(sec: float):
        start = int(sec * SR)
        dur = int(0.50 * SR)
        t = np.arange(dur) / SR
        noise = (np.random.rand(dur) * 2.0 - 1.0)
        env = np.sin(np.pi * t / (dur / SR)) ** 2
        whoosh = 0.20 * noise * env
        end = min(total_samples, start + dur)
        if start < total_samples:
            sfx[start:end] += whoosh[:end - start]

    def add_pinch_click(sec: float):
        start = int(sec * SR)
        dur = int(0.04 * SR)
        t = np.arange(dur) / SR
        click = 0.26 * np.sin(2.0 * np.pi * 2400.0 * t) * np.exp(-t * 80.0)
        end = min(total_samples, start + dur)
        if start < total_samples:
            sfx[start:end] += click[:end - start]

    # Impacts at start of every scene downbeat
    for sc in timeline["scenes"]:
        add_sub_impact(sc["start_sec"])
        # Whoosh sweep 0.5s before transition
        if sc["scene_idx"] < len(timeline["scenes"]):
            add_whoosh(sc["end_sec"] - 0.48)

    # Tactile pinch clicks in Scene 3
    sc3 = timeline["scenes"][2]
    add_pinch_click(sc3["start_sec"] + 2.2)
    add_pinch_click(sc3["start_sec"] + 3.8)

    return sfx


def produce_master_audio(timeline: dict, stem_data: list):
    """Mix vocal stems, music bed with -6.5dB sidechain ducking, and SFX into master WAV."""
    total_samples = int(timeline["total_dur_sec"] * SR)
    voice_track = np.zeros(total_samples, dtype=np.float32)
    speech_envelope = np.zeros(total_samples, dtype=np.float32)

    for idx, sc in enumerate(timeline["scenes"]):
        stem = stem_data[idx]
        v_start = int(sc["vo_start_sec"] * SR)
        v_len = len(stem["samples"])
        v_end = min(total_samples, v_start + v_len)
        voice_track[v_start:v_end] += stem["samples"][:v_end - v_start]

        # Mark speech energy for sidechain ducking
        speech_envelope[v_start:v_end] = 1.0

    # Smooth speech envelope with 15ms attack and 120ms release
    window_len = int(0.08 * SR)
    kernel = np.hanning(window_len)
    kernel /= kernel.sum()
    smoothed_env = np.convolve(speech_envelope, kernel, mode="same")
    smoothed_env = np.clip(smoothed_env * 1.4, 0.0, 1.0)

    # Ducking multiplier: 1.0 when quiet, 0.47 (-6.5dB) during speech
    ducking_gain = 1.0 - 0.53 * smoothed_env

    music = synth_music_bed(total_samples) * ducking_gain
    sfx = build_sfx(timeline, total_samples)

    # Final stereo mix
    master_l = voice_track * 1.15 + music * 0.70 + sfx * 0.85
    master_r = voice_track * 1.15 + music * 0.70 + sfx * 0.85

    # Peak normalization to -0.5 dBFS
    max_val = max(np.max(np.abs(master_l)), np.max(np.abs(master_r)), 1e-4)
    target_peak = 10.0 ** (-0.5 / 20.0)  # ~0.944
    norm_gain = min(1.35, target_peak / max_val)
    master_l = np.clip(master_l * norm_gain, -0.99, 0.99)
    master_r = np.clip(master_r * norm_gain, -0.99, 0.99)

    stereo_interleaved = np.empty((total_samples * 2,), dtype=np.int16)
    stereo_interleaved[0::2] = (master_l * 32767.0).astype(np.int16)
    stereo_interleaved[1::2] = (master_r * 32767.0).astype(np.int16)

    with wave.open(AUDIO_MASTER_WAV, "wb") as wf:
        wf.setnchannels(2)
        wf.setsampwidth(2)
        wf.setframerate(SR)
        wf.writeframes(stereo_interleaved.tobytes())

    print(f"🎵 Master audio synthesized: {AUDIO_MASTER_WAV} ({len(stereo_interleaved) / (SR * 2):.2f}s, Peak Normalized)")


def main():
    timeline, stem_data = asyncio.run(synthesize_and_measure())
    produce_master_audio(timeline, stem_data)


if __name__ == "__main__":
    main()
