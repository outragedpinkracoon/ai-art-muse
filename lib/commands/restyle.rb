#!/usr/bin/env ruby
require_relative "../config"
require_relative "../output"
require_relative "../ollama"
require_relative "../prompts"
require_relative "generate"

RESTYLE_USAGE = <<~USAGE
  Usage: muse restyle <image.png> --style LAYERS [generate opts]
    Re-renders an image's subject in a different style, keeping its seed so the
    composition stays in the same family. The mirror of `regen`: regen keeps the
    style and swaps the subject; restyle keeps the subject and swaps the style.

    A small local model strips the old style out of the saved prompt, so you only
    type the new --style — the subject and its detail carry over.

    e.g. muse restyle output/output_007.png --style chalk
USAGE

# Runs `muse restyle`: take an image, keep its subject and seed, redraw it in a
# new style. Reads the saved prompt + seed from the source's mflux metadata, has
# the regen model strip the old style words out of the prompt, then hands the
# bare subject to Generate with the requested --style.
class Restyle
  # `argv` is the command's raw arguments: source image, then flags to pass
  # through to Generate (which must include --style).
  def initialize(argv)
    @image = argv[0]
    @passthrough = argv[1..] || []
  end

  # Reads the source's prompt + seed, strips the old style to a bare subject, and
  # hands off to Generate with the new --style. Aborts on missing args, missing
  # --style, missing image, or missing metadata.
  def run
    abort RESTYLE_USAGE unless @image && @passthrough.include?("--style")
    abort "Image not found: #{@image}" unless File.exist?(@image)

    meta = Output.extract_mflux_metadata(@image)
    abort "No mflux metadata found in #{@image}" unless meta && meta["prompt"]

    subject = strip_style(meta["prompt"])
    puts "Restyling subject: #{subject}\n\n"

    Generate.new(self.class.build_argv(subject, seed: meta["seed"], passthrough: @passthrough)).run
  end

  # The argv handed to Generate: the bare subject + the user's flags (which must
  # include --style). Generate appends the new style block itself. Pure function
  # of its inputs, so it's easy to test without running mflux/ollama.
  def self.build_argv(subject, seed:, passthrough:)
    argv = [subject]
    argv += ["--seed", seed.to_s] if seed
    argv + passthrough
  end

  private

  # Ask the small local model to drop the art-style/medium words from the saved
  # prompt and return just the subject + its concrete detail. Works regardless of
  # how the original was styled (preset, hand-written, --bare), which a mechanical
  # string strip couldn't.
  def strip_style(prompt)
    system_prompt = Prompts.load_prompt("restyle.txt")
    subject = Ollama.chat(Config::REGEN_MODEL, [
      {role: "system", content: system_prompt},
      {role: "user", content: "PROMPT:\n#{prompt}"}
    ])
    system("ollama stop #{Config::REGEN_MODEL}")
    abort "Restyle model returned nothing." if subject.nil? || subject.empty?
    subject
  end
end
