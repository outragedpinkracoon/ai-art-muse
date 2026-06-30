# Demo recording

Files for the README demo GIF (`docs/images/demo.gif`).

- **`demo.tape`** — [VHS](https://github.com/charmbracelet/vhs) script: the scripted
  terminal session (commands, timing, theme).
- **`fake-muse`** — a demo-only stand-in for the real `muse`. It prints the same
  output the real commands print and renders the matching pre-generated example
  image from `docs/images/` as terminal color blocks (via `chafa`), with small
  sleeps so the recording reads like a live session. It is **not** a working tool —
  it only knows the exact arguments scripted in `demo.tape`, so the recording is
  fast and repeatable instead of running the real 16GB model.

## Re-record

Needs `vhs` and `chafa` (and `ffmpeg`, pulled in by `vhs`):

```bash
brew install vhs chafa
```

Then, from the repo root:

```bash
vhs demo/demo.tape      # writes docs/images/demo.gif
```

## Notes

- The terminal color-block images (`chafa`) are noisy — they're placeholders. The
  intended workflow is to splice the real example PNGs into the GIF afterward with
  a video/GIF editor, using the on-screen image as the slot to replace.
- vhs records inside a headless terminal (ttyd/xterm.js), which has no inline-image
  protocol — that's why images render as color blocks, not real pixels, here.
