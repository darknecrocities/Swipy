#!/usr/bin/env python3
"""Broadcast Audio Producer for Swipy Facebook Reels Showcase Film.

Synthesizes:
1. Emotive neural TTS male voiceover (en-US-AndrewMultilingualNeural via edge-tts).
2. Broadcast vocal dynamics chain (90Hz HPF, 3.2kHz presence EQ lift, LA-2A compressor).
3. Synchronized 120 BPM rhythmic tech beat (kick, snare, hi-hats, sub-bass 808 pulse).
4. Synchronized SFX (sub-bass impacts, whoosh transition sweeps, HUD lock-on chirps, pinch clicks).
5. Sidechain ducking (-6.5dB during dialogue) exporting 48kHz stereo WAV master.

Strictly complies with SkillBuilder cognitive limits (<500 lines).
"""

import asyncio
import os
import subprocess
import wave
import numpy as np
import edge_tts

SR = 48000
BPM = 120.0
BEAT_SEC = 60.0 / BPM  # 0.5s
TOTAL_DUR = 32.0
TOTAL_SAMPLES = int(TOTAL_DUR * SR)

SCRATCH_DIR = "/Users/arronkianparejas/.gemini/antigravity/brain/44f6a692-c641-4a23-bd30-b5abab155805/scratch"
OUTPUT_DIR = "assets/showcase-video"
AUDIO_MASTER_WAV = os.path.join(OUTPUT_DIR, "reels_audio_master.wav")

SCRIPT_LINES = [
    {
        "id": "vo_01_hook",
        "text": "What if the new M6 MacBook was touchscreen? But wait... what if you didn't even have to touch the screen?",
        "start_time": 0.35,
    },
    {
        "id": "vo_02_reveal",
        "text": "Meet Swipy. It turns your built-in MacBook camera into a natural spatial trackpad.",
        "start_time": 5.4,
    },
    {
        "id": "vo_03_tracking",
        "text": "Glide your index finger to move the cursor. Pinch your thumb and index to grab and drag windows anywhere.",
        "start_time": 12.3,
    },
    {
        "id": "vo_04_gestures",
        "text": "Flick four fingers to switch Spaces. 15 native gestures, powered by 21-point Apple Vision entirely on-device.",
        "start_time": 20.2,
    },
    {
        "id": "vo_05_cta",
        "text": "Control your Mac with a wave of your hand. Download Swipy today—link in bio.",
        "start_time": 27.2,
    },
]


async def generate_vocal_stems():
    """Synthesize neural TTS audio lines and apply broadcast dynamics chain."""
    os.makedirs(SCRATCH_DIR, exist_ok=True)
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print("🎙️ Synthesizing emotive neural voiceover (en-US-AndrewMultilingualNeural)...")

    for item in SCRIPT_LINES:
        raw_mp3 = os.path.join(SCRATCH_DIR, f"{item['id']}_raw.mp3")
        clean_wav = os.path.join(SCRATCH_DIR, f"{item['id']}_clean.wav")

        communicate = edge_tts.Communicate(item["text"], "en-US-AndrewMultilingualNeural", rate="+4%")
        await communicate.save(raw_mp3)

        # Broadcast vocal processing chain
        filter_str = (
            "silenceremove=start_periods=1:start_duration=0.01:start_threshold=-42dB:"
            "stop_periods=-1:stop_duration=0.15:stop_threshold=-42dB,"
            "highpass=f=90,"
            "equalizer=f=3200:t=q:w=1.2:g=2.8,"
            "acompressor=threshold=-16dB:ratio=3.2:attack=8:release=80,"
            "volume=1.25"
        )
        cmd = [
            "ffmpeg", "-y", "-i", raw_mp3,
            "-af", filter_str,
            "-ar", str(SR), "-ac", "1",
            clean_wav
        ]
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        print(f"  ✓ Processed: {item['id']}")


def load_wav_mono(path: str) -> np.ndarray:
    """Read uncompressed WAV file as float32 numpy array."""
    with wave.open(path, "rb") as wf:
        n_frames = wf.getnframes()
        data = wf.readframes(n_frames)
        samples = np.frombuffer(data, dtype=np.int16).astype(np.float32) / 32768.0
        return samples


def synth_drum_beat() -> np.ndarray:
    """Synthesize 120 BPM electronic drum grid (kick, snare, hi-hats, 808 sub)."""
    music = np.zeros(TOTAL_SAMPLES, dtype=np.float32)
    t_global = np.arange(TOTAL_SAMPLES) / SR

    # Total 64 beats across 32 seconds
    total_beats = int(TOTAL_DUR / BEAT_SEC)

    for beat in range(total_beats):
        beat_start = int(beat * BEAT_SEC * SR)
        beat_idx_in_bar = beat % 4

        # 1. Kick Drum on Beats 0 & 2
        if beat_idx_in_bar in (0, 2):
            k_len = int(0.26 * SR)
            k_t = np.arange(k_len) / SR
            k_freq = 150.0 * np.exp(-k_t * 18.0) + 48.0
            k_phase = 2.0 * np.pi * np.cumsum(k_freq) / SR
            k_env = np.exp(-k_t * 14.0)
            kick = 0.58 * np.sin(k_phase) * k_env
            end = min(TOTAL_SAMPLES, beat_start + k_len)
            music[beat_start:end] += kick[:end - beat_start]

        # 2. Snare Drum on Beats 1 & 3
        if beat_idx_in_bar in (1, 3):
            s_len = int(0.22 * SR)
            s_t = np.arange(s_len) / SR
            s_body = 0.22 * np.sin(2.0 * np.pi * 185.0 * s_t) * np.exp(-s_t * 22.0)
            s_noise = 0.28 * (np.random.rand(s_len) * 2.0 - 1.0) * np.exp(-s_t * 26.0)
            snare = s_body + s_noise
            end = min(TOTAL_SAMPLES, beat_start + s_len)
            music[beat_start:end] += snare[:end - beat_start]

        # 3. Crisp Hi-Hats on every 8th note
        for sub_beat in (0, 0.5):
            h_start = int((beat + sub_beat) * BEAT_SEC * SR)
            h_len = int(0.045 * SR)
            h_t = np.arange(h_len) / SR
            h_noise = (np.random.rand(h_len) * 2.0 - 1.0) * np.exp(-h_t * 90.0)
            h_val = 0.11 * h_noise
            end = min(TOTAL_SAMPLES, h_start + h_len)
            if h_start < TOTAL_SAMPLES:
                music[h_start:end] += h_val[:end - h_start]

    # 4. Melodic Sub-Bass 808 Synth Pulse
    bass_notes = [55.0, 48.0, 52.0, 43.65]  # A, G, E, F
    for bar in range(16):
        bar_start = int(bar * 2.0 * SR)
        b_freq = bass_notes[bar % len(bass_notes)]
        b_len = int(1.85 * SR)
        b_t = np.arange(b_len) / SR
        b_pulse = 0.24 * np.sin(2.0 * np.pi * b_freq * b_t) * np.exp(-b_t * 1.5)
        b_pulse += 0.08 * np.sin(2.0 * np.pi * (b_freq * 2) * b_t) * np.exp(-b_t * 2.5)
        end = min(TOTAL_SAMPLES, bar_start + b_len)
        music[bar_start:end] += b_pulse[:end - bar_start]

    return music


def synth_sound_effects() -> np.ndarray:
    """Synthesize whooshes, sub-bass impacts, shutter chirps, and tactile pinch clicks."""
    sfx = np.zeros(TOTAL_SAMPLES, dtype=np.float32)

    def add_sub_impact(sec: float):
        start = int(sec * SR)
        dur = int(1.2 * SR)
        t = np.arange(dur) / SR
        wave_sub = 0.45 * np.sin(2.0 * np.pi * 55.0 * np.exp(-t * 2.5) * t) * np.exp(-t * 2.8)
        end = min(TOTAL_SAMPLES, start + dur)
        sfx[start:end] += wave_sub[:end - start]

    def add_whoosh(sec: float):
        start = int(sec * SR)
        dur = int(0.55 * SR)
        t = np.arange(dur) / SR
        noise = (np.random.rand(dur) * 2.0 - 1.0)
        env = np.sin(np.pi * t / (dur / SR)) ** 2
        whoosh = 0.22 * noise * env
        end = min(TOTAL_SAMPLES, start + dur)
        sfx[start:end] += whoosh[:end - start]

    def add_shutter_chirp(sec: float):
        start = int(sec * SR)
        dur = int(0.08 * SR)
        t = np.arange(dur) / SR
        chirp = 0.22 * np.sin(2.0 * np.pi * (1800.0 + 1200.0 * t / 0.08) * t) * np.exp(-t * 40.0)
        end = min(TOTAL_SAMPLES, start + dur)
        sfx[start:end] += chirp[:end - start]

    def add_pinch_click(sec: float):
        start = int(sec * SR)
        dur = int(0.04 * SR)
        t = np.arange(dur) / SR
        click = 0.28 * np.sin(2.0 * np.pi * 2400.0 * t) * np.exp(-t * 80.0)
        end = min(TOTAL_SAMPLES, start + dur)
        sfx[start:end] += click[:end - start]

    # Impacts
    add_sub_impact(0.0)
    add_sub_impact(5.0)

    # Whoosh wipes on scene transitions
    add_whoosh(4.8)
    add_whoosh(11.8)
    add_whoosh(19.8)
    add_whoosh(26.8)

    # HUD Target lock-on chirps
    add_shutter_chirp(14.0)
    add_shutter_chirp(16.5)
    add_shutter_chirp(18.2)

    # Tactile pinch click
    add_pinch_click(15.8)
    add_pinch_click(23.4)

    return sfx


def mix_master_soundtrack():
    """Composite vocals, music bed with -6.5dB sidechain ducking, and SFX."""
    vocal_track = np.zeros(TOTAL_SAMPLES, dtype=np.float32)
    ducking_mask = np.ones(TOTAL_SAMPLES, dtype=np.float32)

    duck_factor = 10.0 ** (-6.5 / 20.0)  # ~0.473 (-6.5 dB)

    print("🎛️ Laying vocal stems onto master timeline...")
    for item in SCRIPT_LINES:
        clean_wav = os.path.join(SCRATCH_DIR, f"{item['id']}_clean.wav")
        samples = load_wav_mono(clean_wav)
        start_idx = int(item["start_time"] * SR)
        end_idx = min(TOTAL_SAMPLES, start_idx + len(samples))
        vocal_track[start_idx:end_idx] += samples[:end_idx - start_idx]

        # Apply smooth sidechain ducking window around voice
        pad_pre = int(0.08 * SR)
        pad_post = int(0.24 * SR)
        d_start = max(0, start_idx - pad_pre)
        d_end = min(TOTAL_SAMPLES, end_idx + pad_post)
        ducking_mask[d_start:d_end] = duck_factor

    # Smooth the ducking envelope with 50ms moving average
    smooth_len = int(0.05 * SR)
    kernel = np.ones(smooth_len) / smooth_len
    ducking_envelope = np.convolve(ducking_mask, kernel, mode="same")

    print("🥁 Synthesizing 120 BPM drum grid and 808 sub-bass...")
    music_bed = synth_drum_beat()

    print("🔊 Synthesizing whoosh wipes, impacts, and HUD chirps...")
    sfx_track = synth_sound_effects()

    # Apply sidechain ducking to music bed
    ducked_music = music_bed * ducking_envelope

    # Master Sum
    master_mix = vocal_track * 1.05 + ducked_music * 0.82 + sfx_track * 0.95

    # Peak soft-clipping limiter (tanh)
    peak = np.max(np.abs(master_mix))
    if peak > 0.95:
        master_mix = np.tanh(master_mix / 0.95) * 0.95

    # Write 16-bit 48kHz Stereo WAV
    print(f"💾 Exporting broadcast master WAV: {AUDIO_MASTER_WAV}")
    int16_samples = (master_mix * 32767.0).astype(np.int16)
    stereo_interleaved = np.empty((TOTAL_SAMPLES * 2,), dtype=np.int16)
    stereo_interleaved[0::2] = int16_samples
    stereo_interleaved[1::2] = int16_samples

    with wave.open(AUDIO_MASTER_WAV, "wb") as wf:
        wf.setnchannels(2)
        wf.setsampwidth(2)
        wf.setframerate(SR)
        wf.writeframes(stereo_interleaved.tobytes())

    print("✅ Master audio soundtrack generated successfully!")


if __name__ == "__main__":
    asyncio.run(generate_vocal_stems())
    mix_master_soundtrack()
