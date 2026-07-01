# Install Guide

Everything this app needs, and how to get it. Commands below use **Homebrew**
(`brew`) as an example — any equivalent installer works.

> **Platform:** any Apple Silicon Mac (M1 or newer). The image model runs on
> Apple's MLX framework, which needs a real Mac GPU (Metal) — it won't run on
> Intel Macs, Linux, or in Docker. Generation peaks around ~17GB of memory, so
> 16GB is tight (close other apps) and 24GB+ is comfortable.

## Dependencies

Only the first three rows (plus the FLUX image model) are **required** to generate
images. **Ollama is optional** — it only runs the models behind `critique`,
`regen`/`restyle`, and `imagine`. Skip it until you want those commands.

| Dependency | Why | Required? | Notes |
|---|---|---|---|
| **Ruby 3.0+** | The `muse` CLI is written in Ruby | Required | macOS ships 2.6, which is too old — install a newer one. No gems needed at runtime. |
| **Python 3 + pip** | Runs `mflux` (the image generator) | Required | macOS ships Python 3; `pip install mflux` pulls it and Apple's MLX. |
| **Hugging Face token** | mflux downloads the FLUX image model on first run | Required | Free token from huggingface.co. |
| **Ollama** | Runs the local text + vision models | Optional | Background service; only needed for `critique`, `regen`/`restyle`, `imagine`. Pull the models once (below). |

### Install

```bash
# 1. Ruby (3.0 or newer)
brew install ruby

# 2. Python 3, then mflux
brew install python
pip install mflux

# 3. Ollama — OPTIONAL (only for critique / regen / restyle / imagine)
brew install ollama
```

Verify mflux installed:

```bash
mflux-generate-flux2 --help
```

### Hugging Face token

mflux pulls the image model from Hugging Face on first generation. Create a
free token at **huggingface.co → Settings → Access Tokens**, then export it:

```bash
export HF_TOKEN=your_token_here      # add to ~/.zshrc to persist
```

## AI models

### Required: the FLUX image model

`generate` (and `--edit`) need this and nothing else. It is **not** an Ollama
model — mflux downloads it from Hugging Face automatically on first
`muse generate` (~16GB, cached after). No manual pull; just set `HF_TOKEN` above.

### Optional: the Ollama models

Each unlocks one extra command. **Pull only the ones you want** — they download
and cache locally, and `muse` works fine without them (the matching command just
won't be available until you pull its model):

```bash
ollama pull qwen2.5vl:7b                                                    # unlocks: critique / compare
ollama pull qwen2.5:3b                                                      # unlocks: regen / restyle
ollama pull gemma4:12b-mlx                                                  # unlocks: imagine
```

| Model | Unlocks | Required? | Source | Approx size |
|---|---|---|---|---|
| `flux2-klein-4b` | `generate` + `--edit` | **Required** | Hugging Face via mflux (`black-forest-labs/FLUX.2-klein-4B`) | ~16GB |
| `qwen2.5vl:7b` | `critique` / `compare` | Optional | Ollama | ~6GB |
| `qwen2.5:3b` | `regen` / `restyle` | Optional | Ollama | ~2GB |
| `gemma4:12b-mlx` | `imagine` | Optional | Ollama | ~8GB |

Model names live in `lib/config.rb` if you want to swap any of them.

## Verify

```bash
ruby --version              # 3.0 or newer
mflux-generate-flux2 --help # mflux is installed and on PATH
echo $HF_TOKEN              # non-empty
ollama list                 # optional — lists whichever optional models you pulled
./muse models               # what muse expects: required vs optional, and what each unlocks
```

### Put `muse` on your PATH (optional)

The `muse` executable lives in the repo root. To call it from anywhere:

```bash
chmod +x muse
mkdir -p ~/.local/bin
ln -s "$PWD/muse" ~/.local/bin/muse      # ~/.local/bin is usually already on PATH
```

If your shell can't find `muse` afterward, add the dir to your PATH:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

Otherwise just run `./muse ...` from the repo root.

## First run

First `muse generate` will be slow — Hugging Face downloads the ~16GB image
model. It's cached, so later runs are fast (tens of seconds per image).

## Links / sources

Tools:

- Ruby — https://www.ruby-lang.org
- Python — https://www.python.org
- mflux — https://github.com/filipstrand/mflux
- Ollama — https://ollama.com/download
- Hugging Face access tokens — https://huggingface.co/settings/tokens

Models:

- `flux2-klein-4b` (image) — https://huggingface.co/black-forest-labs/FLUX.2-klein-4B
- `qwen2.5vl:7b` (vision) — https://ollama.com/library/qwen2.5vl
- `qwen2.5:3b` (regen/restyle) — https://ollama.com/library/qwen2.5
- `gemma4:12b-mlx` (imagine) — https://ollama.com/library/gemma4
