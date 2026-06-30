#!/usr/bin/env ruby
require_relative "../config"
require_relative "../output"
require_relative "../ollama"
require_relative "../prompts"
require_relative "generate"

REGEN_USAGE = <<~USAGE
  Usage: muse regen <image.png> "new subject" [generate opts]
    Reuses the image's saved seed + style block, swaps in your new subject,
    and reruns txt2img. The subject is fused into the original style by a small
    local model so new objects render in-style instead of defaulting to realism.
USAGE

# Runs `muse regen`: take a known-good image, keep its seed and style, but draw a
# different subject. Reads the sidecar/EXIF for the original prompt + seed, splits
# subject from style, has the regen model weave the new subject into the style,
# then hands off to Generate as a normal txt2img run.
class Regen
  # `argv` is the command's raw arguments: source image, new subject, then any
  # extra flags to pass through to Generate.
  def initialize(argv)
    @image = argv[0]
    @subject = argv[1]
    @passthrough = argv[2..] || []
  end

  # Reads the source's seed + style, fuses the new subject into that style, and
  # hands off to Generate. Aborts on missing args, image, or metadata.
  def run
    abort REGEN_USAGE unless @image && @subject
    abort "Image not found: #{@image}" unless File.exist?(@image)

    meta = Output.extract_mflux_metadata(@image)
    abort "No mflux metadata found in #{@image}" unless meta && meta["prompt"]

    style = self.class.style_block(meta["prompt"])
    subject = fuse(@subject, style)
    prompt = "#{subject}, #{style}"
    puts "Regen prompt: #{prompt}\n\n"

    Generate.new(self.class.build_argv(prompt, seed: meta["seed"], passthrough: @passthrough)).run
  end

  # The good prompts are shaped "subject, <style descriptors...>". Everything after
  # the first comma is the reusable style block; the subject is what we replace.
  def self.style_block(prompt)
    prompt.split(",", 2)[1].to_s.strip
  end

  # The argv handed to Generate. We've already baked the full style block into the
  # prompt, so --bare suppresses Generate's default style layer (no duplication).
  # Pure function of its inputs, so it's easy to test without running mflux/ollama.
  def self.build_argv(prompt, seed:, passthrough:)
    argv = [prompt, "--bare"]
    argv += ["--seed", seed.to_s] if seed
    argv + passthrough
  end

  private

  # Ask the small local model to rewrite just the subject phrase in the style's
  # vocabulary. Code then prepends it to the full style block, so subject always
  # leads (a small model won't reliably reorder the long style block itself).
  def fuse(subject, style)
    system_prompt = Prompts.load_prompt("regen.txt")
    user = "STYLE:\n#{style}\n\nSUBJECT:\n#{subject}"
    fused = Ollama.chat(Config::REGEN_MODEL, [
      {role: "system", content: system_prompt},
      {role: "user", content: user}
    ])
    system("ollama stop #{Config::REGEN_MODEL}")
    abort "Regen model returned nothing." if fused.nil? || fused.empty?
    fused
  end
end
