# Ruby Style Guide

High-level conventions for `muse`. These describe how the code already works — follow them so new code reads like the old code. Mechanical formatting is handled by `standardrb` (`rake lint`); this guide covers the things a linter can't.

## Modules vs. classes

- **Stateless helpers → modules** with `def self.x`. They're namespaced free functions plus constants — no instance state to hold (`Styles`, `Prompts`, `Output`, `Ollama`, `Config`).
- **Stateful work → classes.** If it parses input into ivars and then acts on it, it's an object (`Generate`, `Regen`, `GenerateRequest`, …).

Rule of thumb: **state → class, stateless helpers → module.** Don't wrap pure functions in a class just to call `.new`.

## Commands

Every subcommand is a class in `lib/commands/`, all the same shape:

```ruby
Object.const_get(klass).new(ARGV).run
```

- `initialize(argv)` parses arguments into ivars — no work, no I/O.
- `run` does the work and returns nothing meaningful; it `abort`s on bad input.
- Pure, side-effect-free logic (command building, string transforms) is a **class method** (`self.build_command`, `self.build_argv`, `self.style_block`) so it can be unit-tested without running mflux or ollama.
- Private instance methods are the imperative steps `run` orchestrates.

## Configuration

All constants — model names, endpoints, mflux defaults — live in `lib/config.rb`. Nothing else hard-codes them. Retargeting a model or shifting a default is a one-file edit.

## Errors

- **`abort`** for user errors: bad/missing args (print the command's `USAGE`), a missing file, an invalid value. The message tells the user what to fix.
- **`warn`** for soft warnings where the run can still proceed (e.g. an ignored flag).
- Don't rescue broadly. Let genuinely unexpected failures surface.

## Comments

- Every class and module gets a **one-line description** of what it's for.
- Every method gets a comment covering **what goes in, what comes out, and what it does**.
- Comments explain **why**, not what the code plainly says — especially the non-obvious external quirks (mflux dividing by `steps - 1`, EXIF metadata extraction, distilled models locking guidance). These are the comments that save the next person an afternoon.

## Tests

- Unit tests (`test/`, run by `rake test`) are **fast and offline** — no models, no network. Stub the transport (`Ollama.post`) rather than reaching out.
- Test the pure class methods and the argv parsing directly; reach into ivars with small helpers when there's no public accessor.
- Anything that needs real models is an **end-to-end smoke test** (`rake smoke`), never a unit test.
- One test file per source file, mirroring `lib/`.

## Before committing

`rake` (lint + tests) is green.
