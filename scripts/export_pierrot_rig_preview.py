"""Package actual Godot captures; no source sprites are modified."""

from pathlib import Path

from PIL import Image


def main() -> None:
    output = Path(__file__).resolve().parents[1] / "output/pierrot_rig_20260908"
    sources = sorted((output / "frames").glob("frame_*.png"))
    if len(sources) != 92:
        raise SystemExit("Run render_pierrot_rig_preview.gd with -- --movie first.")
    frames = []
    for source in sources:
        with Image.open(source) as capture:
            frame = capture.convert("RGB")
            frames.append(frame)
    sample = Image.new("RGB", (1280, 720 * 4))
    for index, frame_index in enumerate((0, 25, 44, 63)):
        sample.paste(frames[frame_index], (0, index * 720))
    palette = sample.quantize(colors=256, method=Image.Quantize.MEDIANCUT)
    indexed = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in frames]
    durations = [30 if index % 3 != 2 else 40 for index in range(len(indexed))]
    target = output / "pierrot_thrust_rig_preview.gif"
    indexed[0].save(target, save_all=True, append_images=indexed[1:],
                    duration=durations, loop=0, optimize=True, disposal=1)
    with Image.open(target) as check:
        assert check.n_frames > 30
        print(f"{target}: {check.n_frames} frames, {check.size}, {target.stat().st_size} bytes")


if __name__ == "__main__":
    main()
