#!/usr/bin/env ruby
require "shellwords"
require_relative "../config"
require_relative "../output"
require_relative "../styles"
require_relative "../generate_request"

GENERATE_USAGE = <<~USAGE
  Usage: muse generate "prompt" [--style LAYERS] [--bare] [--edit <image>] [--steps N] [--seed N] [--guidance N] [--lora-style NAME] [--lora-scale N] [--no-lora] [--prev] [--verbose]
    Default style: illustration. Layers: illustration|chalk|sketch|delicate + character|object. --bare: no style.
    LoRA: illustration @1.0 applied by default (txt2img + edit). --no-lora to disable.
USAGE

# Runs a single `muse generate` invocation: validate, build the mflux command,
# run it, and write the metadata sidecar.
class Generate
  # `argv` is the command's raw arguments; parsed into a GenerateRequest.
  def initialize(argv)
    @request = GenerateRequest.parse(argv)
  end

  # Validates, resolves the style, runs mflux, and writes the sidecar. No return
  # value; aborts on bad input or mflux failure.
  def run
    validate!
    resolve_style
    announce
    run_mflux!
    save_sidecar
  end

  # Builds the mflux CLI command — flux2-edit for --edit, flux2-generate for txt2img.
  # Pure function of the request + resolved prompt, so it's easy to test in isolation.
  def self.build_command(request, final_prompt, out_path:, negative_prompt: nil)
    [
      request.binary,
      "--model", Config::IMAGE_MODEL,
      request.edit ? ["--image-paths", request.edit.shellescape] : nil,
      "--prompt", final_prompt.shellescape,
      (Config::NEGATIVE_PROMPT_SUPPORTED && negative_prompt) ? ["--negative-prompt", negative_prompt.shellescape] : nil,
      "--steps", request.steps || request.default_steps,
      request.seed ? ["--seed", request.seed] : nil,
      Config::GUIDANCE_SUPPORTED ? ["--guidance", request.guidance || Config::DEFAULT_GUIDANCE] : nil,
      request.lora_style ? ["--lora-style", request.lora_style.shellescape] : nil,
      (request.lora_style && request.lora_scale) ? ["--lora-scales", request.lora_scale] : nil,
      "--output", out_path
    ].flatten.compact.join(" ")
  end

  private

  attr_reader :request

  # Aborts with usage/help text if the request is unusable: no prompt, a missing
  # --edit source image, or a steps value mflux can't handle.
  def validate!
    abort GENERATE_USAGE unless request.prompt
    abort "Image not found: #{request.edit}" if request.edit && !File.exist?(request.edit)
    # mflux divides by (num_steps - 1), so a single step is a ZeroDivisionError.
    abort "Steps must be 2 or more (mflux divides by steps - 1)." if request.steps && request.steps.to_i < 2
  end

  # Looks up the requested style and sets @final_prompt (subject + positive
  # style snippet) and @negative (negative snippet, or nil if empty/absent).
  def resolve_style
    style = request.style ? Styles.lookup(request.style) : nil
    @final_prompt = request.final_prompt(style&.positive)
    @negative = style&.negative.then { |n| n&.empty? ? nil : n }
  end

  # Prints the final prompt about to be rendered.
  def announce
    puts "Generating: #{@final_prompt}"
  end

  # Reserves the next output path, builds and runs the mflux command (echoing it
  # in --verbose), and aborts if mflux exits non-zero.
  def run_mflux!
    @out_path = Output.next_output_path
    cmd = Generate.build_command(request, @final_prompt, out_path: @out_path, negative_prompt: @negative)
    puts "Command: #{cmd}" if request.verbose
    abort "mflux failed — no image written." unless system(cmd)
  end

  # Writes the metadata sidecar next to the image, prints the final path, and
  # opens it in Preview if --prev was passed.
  def save_sidecar
    @out_path = Output.write_sidecar(@out_path, prompt: @final_prompt, mode: request.editing? ? "edit" : "txt2img",
      source: request.edit, lora_style: request.lora_style, lora_scale: request.lora_scale)
    puts "Saved: #{@out_path}"
    `open -a Preview #{@out_path}` if request.preview
  end
end
