require_relative "config"

# A parsed `muse generate` invocation. Knows its mode, which mflux binary to run,
# and how the final prompt is assembled.
class GenerateRequest
  attr_reader :prompt, :edit, :steps, :seed, :guidance,
    :style, :lora_style, :lora_scale, :preview, :verbose

  def initialize(prompt:, edit:, steps:, seed:, guidance:,
    style:, lora_style:, lora_scale:, preview:, verbose:)
    @prompt = prompt
    @edit = edit
    @steps = steps
    @seed = seed
    @guidance = guidance
    @style = style
    @lora_style = lora_style
    @lora_scale = lora_scale
    @preview = preview
    @verbose = verbose
  end

  def editing? = !edit.nil?

  def binary = editing? ? "mflux-generate-flux2-edit" : "mflux-generate-flux2"

  def default_steps = editing? ? Config::DEFAULT_STEPS_EDIT : Config::DEFAULT_STEPS_TXT2IMG

  def final_prompt(style_text) = [prompt, style_text].compact.join(", ")

  def self.parse(argv)
    edit = flag(argv, "--edit")
    new(
      prompt: argv[0],
      edit: edit,
      preview: argv.include?("--prev"),
      verbose: argv.include?("--verbose"),
      steps: flag(argv, "--steps"),
      seed: flag(argv, "--seed"),
      guidance: flag(argv, "--guidance"),
      style: style_for(argv, editing: !edit.nil?),
      lora_style: lora_style_for(argv),
      lora_scale: flag(argv, "--lora-scale") || Config::DEFAULT_LORA_SCALE
    )
  end

  # Prose style never applies to --edit: appending it would muddy the edit
  # instruction. An explicit --style is ignored (with a warning) in edit mode.
  # For txt2img, explicit --style / --bare win, else the :default auto-style.
  def self.style_for(argv, editing:)
    if editing
      warn "muse: --style is ignored in edit mode (use --lora-style)" if flag(argv, "--style")
      return nil
    end
    return nil if argv.include?("--bare")
    flag(argv, "--style") || :default
  end

  # Same precedence for the style LoRA: --no-lora / explicit --lora-style win.
  # The default LoRA applies to edit too — it tweaks weights, not the prompt
  # text, so it can't corrupt the --edit instruction the way prose style would.
  def self.lora_style_for(argv)
    return nil if argv.include?("--no-lora")
    flag(argv, "--lora-style") || Config::DEFAULT_LORA_STYLE
  end

  # Value following a flag, or nil if the flag is absent.
  def self.flag(argv, name)
    i = argv.index(name)
    i ? argv[i + 1] : nil
  end
end
