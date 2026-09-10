"""Package unmodified frames captured by Godot into a looping review GIF."""

from pathlib import Path

from PIL import Image


def main() -> None:
    directory = Path(__file__).resolve().parents[1] / "output/pierrot_native_20260909"
    sources = sorted((directory / "frames").glob("frame_*.png"))
    if len(sources) != 112:
        raise SystemExit("Capture render_preview.gd with -- --movie first (112 frames).")
    frames = []
    for source in sources:
        with Image.open(source) as capture:
            frames.append(capture.convert("RGB"))
    # One shared palette avoids colour flicker between successive renderer frames.
    palette = frames[0].quantize(colors=256, method=Image.Quantize.MEDIANCUT)
    indexed = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in frames]
    target = directory / "pierrot_native_idle.gif"
    indexed[0].save(target, save_all=True, append_images=indexed[1:], duration=50,
                    loop=0, optimize=True, disposal=1)
    with Image.open(target) as result:
        assert result.n_frames > 90
        assert result.size == (1440, 900)
        print(f"{target}: {result.n_frames} frames; {target.stat().st_size} bytes")


if __name__ == "__main__":
    main()
