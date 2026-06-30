# Install Guide

Everything this app needs, and how to get it. Commands below use **Homebrew**
(`brew`) as an example — any equivalent installer works.

> **Platform:** any Apple Silicon Mac (M1 or newer). The image model runs on
> Apple's MLX framework, which needs a real Mac GPU (Metal) — it won't run on
> Intel Macs, Linux, or in Docker. Generation peaks around ~17GB of memory, so
> 16GB is tight (close other apps) and 24GB+ is comfortable.

## Dependencies

| Dependency | Why | Notes |
|---|---|---|
| **Ruby 3.0+** | The `muse` CLI is written in Ruby | macOS ships 2.6, which is too old — install a newer one. No gems needed at runtime. |
| **Python 3 + pip** | Runs `mflux` (the image generator) | macOS ships Python 3; `pip install mflux` pulls it and Apple's MLX. |
| **Ollama** | Runs the local text + vision models | Background service; pull the models once (below). |
| **Hugging Face token** | mflux downloads the image model on first run | Free token from huggingface.co. |

### Install

```bash
# 1. Ruby (3.0 or newer)
brew install ruby

# 2. Python 3, then mflux
brew install python
pip install mflux

# 3. Ollama
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

Pull the Ollama models once — they download and cache locally:

```bash
ollama pull qwen2.5vl:7b                                                    # vision / critique
ollama pull qwen2.5:3b                                                      # regen + restyle rewrites
ollama pull hf.co/yuxinlu1/gemma-4-12B-it-Claude-4.6-4.8-Opus-GGUF:Q4_K_M   # brainstorm chat
```

The image model is **not** an Ollama model — mflux downloads it from Hugging
Face automatically on first `muse generate` (~16GB, cached after).

| Model | Role | Source | Approx size |
|---|---|---|---|
| `flux2-klein-4b` | Image generation (txt2img + edit) | Hugging Face via mflux (`black-forest-labs/FLUX.2-klein-4B`) | ~16GB |
| `qwen2.5vl:7b` | Vision critique / compare | Ollama | ~6GB |
| `qwen2.5:3b` | regen / restyle subject + style rewrites | Ollama | ~2GB |
| `hf.co/yuxinlu1/gemma-4-12B-it-Claude-4.6-4.8-Opus-GGUF:Q4_K_M` | brainstorm prompt chat | Ollama (Hugging Face GGUF) | ~7GB |

Model names live in `lib/config.rb` if you want to swap any of them.

## Verify

```bash
ruby --version              # 3.0 or newer
mflux-generate-flux2 --help # mflux is installed and on PATH
ollama list                 # the three pulled models appear
echo $HF_TOKEN              # non-empty
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
- gemma brainstorm GGUF — https://huggingface.co/yuxinlu1/gemma-4-12B-it-Claude-4.6-4.8-Opus-GGUF
