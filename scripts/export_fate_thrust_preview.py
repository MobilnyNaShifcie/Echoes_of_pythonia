"""Package real Godot frame captures as a review GIF; does not modify game art."""

from pathlib import Path

from PIL import Image


def main() -> None:
    output = Path(__file__).resolve().parents[1] / "output/fate_thrust_20260908"
    sources = sorted((output / "frames").glob("frame_*.png"))
    if not sources:
        raise SystemExit("Run render_fate_thrust_preview.gd first.")
    frames = []
    for source in sources:
        with Image.open(source) as capture:
            frame = capture.convert("RGB")
            frame.thumbnail((960, 540), Image.Resampling.LANCZOS)
            frames.append(frame)
    # A shared palette prevents the unchanged background flickering between frames.
    sample = Image.new("RGB", (960, 540 * 4))
    for index, fraction in enumerate((0.0, 0.4, 0.6, 0.8)):
        sample.paste(frames[int((len(frames) - 1) * fraction)], (0, index * 540))
    palette = sample.quantize(colors=256, method=Image.Quantize.MEDIANCUT)
    indexed = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in frames]
    # Captured every second frame at fixed 60 FPS. GIF durations are multiples of 10 ms.
    durations = [30 if index % 3 != 2 else 40 for index in range(len(indexed))]
    durations[-1] += 800
    target = output / "fate_thrust_preview.gif"
    indexed[0].save(target, save_all=True, append_images=indexed[1:],
                    duration=durations, loop=0, optimize=True, disposal=1)
    with Image.open(target) as check:
        assert check.n_frames > 10
        print(f"{target}: {check.n_frames} frames, {check.size}, {target.stat().st_size} bytes")


if __name__ == "__main__":
    main()
