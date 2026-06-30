# Contributing

Thanks for your interest in `muse`. It's a small personal tool, but issues and pull requests are welcome.

## Reporting issues

Open an issue with:

- what you ran (the exact `muse` command),
- what you expected vs. what happened,
- your setup: macOS version, chip (M1/M2/…), RAM, and Ruby/Python/Ollama/mflux versions.

For generation problems, the contents of `smoke-test/smoke_error.txt` after a `rake smoke` run are often the fastest clue. The **[Troubleshooting guide](docs/troubleshooting.md)** covers the common snags first.

## Development setup

Follow the **[Install Guide](docs/install-guide.md)** to get the dependencies and models. Then, from the repo root, install the development gems once:

```bash
bundle install   # rake, standard, minitest (dev/test tooling)
```

Run the checks (prefix with `bundle exec` so they use the locked gem versions):

```bash
bundle exec rake          # lint + unit tests — fast, no models or network
bundle exec rake test     # unit tests only
bundle exec rake lint     # standardrb only
```

The unit tests run offline (no models, no network); the HTTP/model calls are stubbed. Keep them that way — anything needing real models belongs in the smoke test.

## Architecture

`muse` is a thin dispatcher over a set of command objects.

```
muse <cmd> argv
  └─ muse (entrypoint): looks <cmd> up in COMMANDS, requires the file,
       runs Command.new(argv).run
        ├─ Generate / Regen / Restyle / Imagine / Critique  (lib/commands/)
        │     parse argv → ivars, then orchestrate the work
        ├─ mflux  (image generation / edit)  via a built shell command
        └─ Ollama (vision + text models)     via local HTTP (lib/ollama.rb)
```

Supporting modules (`lib/`):

- **`Config`** — all model names, the Ollama endpoint, and mflux defaults.
- **`GenerateRequest`** — a parsed `generate` invocation; knows its mode, which mflux binary to run, and how the final prompt is assembled.
- **`Styles`** — resolves named style presets (`prompts/styles.json`) into prompt text.
- **`Prompts`** — loads the system-prompt text files in `prompts/`.
- **`Output`** — names output files, and reads/writes the JSON **sidecar** next to each image.

Two ideas worth knowing before you change things:

- **The sidecar round-trip.** mflux embeds the run's metadata (prompt, seed, model, …) in the PNG's EXIF. `Output` extracts that and writes an `output_NNN.json` sidecar. `regen` and `restyle` read it back to recover the original prompt and seed — that's how they reuse a known-good result.
- **Small model as a rewriter.** `regen` (new subject, same style) and `restyle` (same subject, new style) both ask a small local text model to split or fuse the subject and style of the saved prompt, then hand the result to `Generate` as an ordinary txt2img run. They don't reimplement generation — they massage the prompt and delegate.

The conventions behind all this are in the **[Style Guide](docs/style-guide.md)**.

## Pull requests

Before opening a PR:

1. `rake` passes (lint **and** tests are green).
2. New behaviour has a unit test where it can be tested offline.
3. If you added or changed a command or flag, update its usage string, the `muse` header comment, and the **[User Guide](docs/user-guide.md)**.
4. Run `rake smoke` if you touched the generation/critique pipeline.

Keep the style consistent — see the **[Style Guide](docs/style-guide.md)**. In short: stateless helpers are modules, stateful commands are classes (`.new(argv).run`), and every class/module gets a one-line description and every method a comment.

## Code of conduct

Be kind and constructive. Harassment or hostility isn't welcome here.
