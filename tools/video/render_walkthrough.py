#!/usr/bin/env python3
"""Render the Godot walkthrough capture with a glowing trial-style cursor."""

from __future__ import annotations

import argparse
import json
import math
import subprocess
import wave
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


SFX_FILES = {
    "ui_click": "ui-click.ogg",
    "ui_back": "ui-back.ogg",
    "room_turn": "room-turn.ogg",
    "item_pickup": "item-pickup.ogg",
    "paper_pickup": "paper-pickup.ogg",
    "book_open": "book-open.ogg",
    "page_turn": "page-turn.ogg",
    "drawer_open": "drawer-open.ogg",
    "wardrobe_open": "wardrobe-open.ogg",
    "sewing": "sewing.ogg",
    "soft_place": "soft-place.ogg",
    "wood_connect": "wood-connect.ogg",
    "train_run": "train-run.ogg",
    "metal_click": "metal-click.ogg",
    "lock_latch": "lock-latch.ogg",
    "door_open": "door-open.ogg",
    "keypad_tick": "keypad-tick.ogg",
    "tv_button": "tv-button.ogg",
    "combine": "combine.ogg",
    "crystal": "crystal.ogg",
}

SFX_GAIN = {
    "ui_click": 0.16,
    "ui_back": 0.17,
    "room_turn": 0.14,
    "page_turn": 0.16,
    "tv_button": 0.12,
    "keypad_tick": 0.16,
    "metal_click": 0.18,
    "paper_pickup": 0.22,
    "book_open": 0.20,
    "door_open": 0.24,
    "lock_latch": 0.22,
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("capture_dir", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--ffmpeg", type=Path, required=True)
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    return parser.parse_args()


def ease(value: float) -> float:
    return value * value * (3.0 - 2.0 * value)


def interpolate(start: tuple[float, float], end: tuple[float, float], value: float) -> tuple[float, float]:
    amount = ease(max(0.0, min(1.0, value)))
    return (
        start[0] + (end[0] - start[0]) * amount,
        start[1] + (end[1] - start[1]) * amount,
    )


def cursor_sprite(click_progress: float | None = None, intensity: float = 1.0) -> Image.Image:
    size = 112
    center = size // 2

    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse(
        (center - 21, center - 21, center + 21, center + 21),
        fill=(104, 135, 255, int(74 * intensity)),
    )
    glow_draw.ellipse(
        (center - 12, center - 12, center + 12, center + 12),
        fill=(134, 222, 255, int(132 * intensity)),
    )
    glow = glow.filter(ImageFilter.GaussianBlur(10))

    sharp = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sharp)
    draw.ellipse(
        (center - 7, center - 7, center + 7, center + 7),
        fill=(154, 221, 255, int(115 * intensity)),
    )
    draw.ellipse(
        (center - 4, center - 4, center + 4, center + 4),
        fill=(247, 253, 255, int(250 * intensity)),
    )
    draw.ellipse(
        (center - 1.5, center - 1.5, center + 1.5, center + 1.5),
        fill=(255, 255, 255, int(255 * intensity)),
    )

    if click_progress is not None:
        progress = max(0.0, min(1.0, click_progress))
        radius = 10.0 + 27.0 * ease(progress)
        alpha = int(220 * (1.0 - progress) * intensity)
        width = 3 if progress < 0.55 else 2
        draw.ellipse(
            (center - radius, center - radius, center + radius, center + radius),
            outline=(174, 229, 255, alpha),
            width=width,
        )

    glow.alpha_composite(sharp)
    return glow


def paint_cursor(
    base: Image.Image,
    position: tuple[float, float],
    click_progress: float | None = None,
    trail: list[tuple[float, float]] | None = None,
    cursor_scale: float = 1.0,
) -> Image.Image:
    frame = base.copy()
    sprite_size = max(1, round(112 * cursor_scale))
    sprite_offset = sprite_size // 2

    def scaled_sprite(progress: float | None, intensity: float = 1.0) -> Image.Image:
        sprite = cursor_sprite(progress, intensity)
        if sprite_size != 112:
            sprite = sprite.resize((sprite_size, sprite_size), Image.Resampling.LANCZOS)
        return sprite

    if trail:
        for index, point in enumerate(trail[-5:]):
            alpha = (index + 1) / max(1, len(trail[-5:]))
            sprite = scaled_sprite(None, 0.12 + 0.15 * alpha)
            frame.alpha_composite(sprite, (round(point[0] - sprite_offset), round(point[1] - sprite_offset)))
    sprite = scaled_sprite(click_progress)
    frame.alpha_composite(sprite, (round(position[0] - sprite_offset), round(position[1] - sprite_offset)))
    return frame.convert("RGB")


def readable_hold(image_name: str, action: dict) -> float:
    """Give text-heavy screens enough time to be read at a natural pace."""
    explicit = float(action.get("hold", 0.30))
    name = image_name.lower()

    if name.endswith("escaped-to-pharmacy.png"):
        return max(explicit, 3.5)
    if "title-settings" in name:
        return max(explicit, 4.0)
    if "title" in name:
        return max(explicit, 1.8)
    if "first-letter" in name:
        return max(explicit, 5.5)
    if "diary-00" in name:
        return max(explicit, 2.8)
    if any(f"diary-{page:02d}" in name for page in [1, 2, 3, 4, 9, 10, 11, 12]):
        return max(explicit, 5.2)
    if any(f"diary-{page:02d}" in name for page in [5, 6, 7, 8]):
        return max(explicit, 2.8)
    if "mother-note" in name:
        return max(explicit, 5.0)
    if "train-order-clue" in name or "shoe-size-240" in name:
        return max(explicit, 3.2)
    if any(f"storybook-{page:02d}" in name for page in range(1, 6)):
        return max(explicit, 6.0)
    if "storybook-code-1366" in name:
        return max(explicit, 4.0)
    if "tv-volume-14" in name:
        return max(explicit, 3.0)
    if "tv-volume-" in name:
        return max(explicit, 0.28)
    if "phone-" in name or "shoe-code-" in name:
        return max(explicit, 0.75)

    detail_keywords = [
        "book", "diary", "needle", "thread", "dresser", "wardrobe", "bear", "bed",
        "train", "page", "shoe", "cabinet", "remote", "sofa", "battery", "clock",
        "door", "letter", "phone",
    ]
    if any(keyword in name for keyword in detail_keywords):
        return max(explicit, 1.45)
    return max(explicit, 0.85)


def decode_audio(ffmpeg: Path, source: Path, duration: float | None = None, loop: bool = False) -> np.ndarray:
    command = [str(ffmpeg), "-v", "error"]
    if loop:
        command += ["-stream_loop", "-1"]
    command += ["-i", str(source)]
    if duration is not None:
        command += ["-t", f"{duration:.6f}"]
    command += ["-f", "f32le", "-ac", "2", "-ar", "48000", "pipe:1"]
    raw = subprocess.check_output(command)
    return np.frombuffer(raw, dtype="<f4").reshape(-1, 2)


def write_audio(
    ffmpeg: Path,
    repo: Path,
    output: Path,
    duration: float,
    childhood_start: float,
    events: list[dict],
) -> None:
    sample_rate = 48000
    total_samples = math.ceil(duration * sample_rate)
    mix = np.zeros((total_samples, 2), dtype=np.float32)

    pharmacy_duration = max(0.0, min(duration, childhood_start))
    childhood_duration = max(0.0, duration - pharmacy_duration)
    if pharmacy_duration > 0:
        pharmacy = decode_audio(
            ffmpeg,
            repo / "assets/audio/music/pharmacy-ambient.ogg",
            pharmacy_duration,
            loop=True,
        )
        mix[: len(pharmacy)] += pharmacy * 0.075
    if childhood_duration > 0:
        childhood = decode_audio(
            ffmpeg,
            repo / "assets/audio/music/childhood-ambient.ogg",
            childhood_duration,
            loop=True,
        )
        start = round(pharmacy_duration * sample_rate)
        end = min(total_samples, start + len(childhood))
        mix[start:end] += childhood[: end - start] * 0.075

    cache: dict[str, np.ndarray] = {}
    for event in events:
        key = event.get("sfx", "")
        filename = SFX_FILES.get(key)
        if not filename:
            continue
        if key not in cache:
            cache[key] = decode_audio(ffmpeg, repo / "assets/audio/sfx" / filename)
        sound = cache[key]
        start = round(float(event["time"]) * sample_rate)
        if start >= total_samples:
            continue
        end = min(total_samples, start + len(sound))
        gain = SFX_GAIN.get(key, 0.20)
        mix[start:end] += sound[: end - start] * gain

    peak = float(np.max(np.abs(mix))) if mix.size else 0.0
    if peak > 0.94:
        mix *= 0.94 / peak
    pcm = (np.clip(mix, -1.0, 1.0) * 32767.0).astype("<i2")
    with wave.open(str(output), "wb") as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(sample_rate)
        wav.writeframes(pcm.tobytes())


def main() -> None:
    args = parse_args()
    manifest = json.loads((args.capture_dir / "manifest.json").read_text(encoding="utf-8"))
    width = int(manifest["width"])
    height = int(manifest["height"])
    fps = int(manifest["fps"])
    steps = manifest["steps"]

    args.output.parent.mkdir(parents=True, exist_ok=True)
    silent_video = args.output.with_suffix(".silent.mp4")
    mixed_wav = args.output.with_suffix(".mix.wav")

    ffmpeg_command = [
        str(args.ffmpeg),
        "-y",
        "-v",
        "warning",
        "-f",
        "rawvideo",
        "-pix_fmt",
        "rgb24",
        "-s",
        f"{width}x{height}",
        "-r",
        str(fps),
        "-i",
        "pipe:0",
        "-an",
        "-c:v",
        "libx264",
        "-preset",
        "slow",
        "-crf",
        "12",
        "-tune",
        "animation",
        "-pix_fmt",
        "yuv420p",
        "-movflags",
        "+faststart",
        str(silent_video),
    ]
    encoder = subprocess.Popen(ffmpeg_command, stdin=subprocess.PIPE)
    if encoder.stdin is None:
        raise RuntimeError("ffmpeg 입력 파이프를 열지 못했습니다.")

    frame_count = 0
    cursor_scale = width / 1280.0
    cursor = (640.0 * cursor_scale, 680.0 * cursor_scale)
    events: list[dict] = []
    childhood_start = 0.0

    def emit(base: Image.Image, position: tuple[float, float], click: float | None = None, trail=None) -> None:
        nonlocal frame_count
        encoder.stdin.write(paint_cursor(base, position, click, trail, cursor_scale).tobytes())
        frame_count += 1

    def emit_for(base: Image.Image, seconds: float, position: tuple[float, float]) -> None:
        for _ in range(max(1, round(seconds * fps))):
            emit(base, position)

    for step_index, step in enumerate(steps):
        base = Image.open(args.capture_dir / step["image"]).convert("RGBA")
        action = step["action"]
        action_type = action.get("type", "hold")

        if action_type == "hold":
            emit_for(base, readable_hold(step["image"], action), cursor)
            continue

        target = tuple(float(value) for value in action["to"])
        if action_type == "drag":
            start = tuple(float(value) for value in action["from"])
            travel_frames = max(1, round(0.42 * fps))
            for frame in range(travel_frames):
                cursor = interpolate(cursor, start, (frame + 1) / travel_frames)
                emit(base, cursor)
            emit_for(base, 0.24, start)
            drag_frames = max(1, round(0.95 * fps))
            trail: list[tuple[float, float]] = []
            for frame in range(drag_frames):
                cursor = interpolate(start, target, (frame + 1) / drag_frames)
                trail.append(cursor)
                emit(base, cursor, trail=trail)
        else:
            travel_frames = max(1, round(0.48 * fps))
            start = cursor
            for frame in range(travel_frames):
                cursor = interpolate(start, target, (frame + 1) / travel_frames)
                emit(base, cursor)

        cursor = target
        emit_for(base, readable_hold(step["image"], action), cursor)
        event_time = frame_count / fps
        if action.get("sfx"):
            events.append({"time": event_time, "sfx": action["sfx"]})
        if step_index == 5:
            childhood_start = event_time + 0.12
        click_frames = max(1, round(0.24 * fps))
        for frame in range(click_frames):
            emit(base, cursor, frame / max(1, click_frames - 1))

    encoder.stdin.close()
    result = encoder.wait()
    if result != 0:
        raise RuntimeError(f"무음 영상 렌더링 실패: {result}")

    duration = frame_count / fps
    write_audio(args.ffmpeg, args.repo, mixed_wav, duration, childhood_start, events)
    subprocess.run(
        [
            str(args.ffmpeg),
            "-y",
            "-v",
            "warning",
            "-i",
            str(silent_video),
            "-i",
            str(mixed_wav),
            "-c:v",
            "copy",
            "-c:a",
            "aac",
            "-b:a",
            "160k",
            "-shortest",
            "-movflags",
            "+faststart",
            "-metadata",
            "title=Mind Pharmacy - Childhood Full Navigation Walkthrough",
            str(args.output),
        ],
        check=True,
    )
    silent_video.unlink(missing_ok=True)
    mixed_wav.unlink(missing_ok=True)
    print(json.dumps({"frames": frame_count, "duration": duration, "events": len(events)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
