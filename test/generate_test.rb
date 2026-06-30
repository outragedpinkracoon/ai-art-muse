require "minitest/autorun"
require_relative "../lib/config"
require_relative "../lib/generate_request"
require_relative "../lib/output"
require_relative "../lib/commands/generate"

class GenerateRequestTest < Minitest::Test
  def test_parses_prompt
    assert_equal "a raccoon", GenerateRequest.parse(["a raccoon"]).prompt
  end

  def test_defaults
    r = GenerateRequest.parse(["a raccoon"])
    refute r.preview
    refute r.verbose
    assert_nil r.steps
    assert_nil r.seed
    assert_nil r.edit
  end

  def test_flags
    r = GenerateRequest.parse(["a raccoon", "--prev", "--verbose"])
    assert r.preview
    assert r.verbose
  end

  def test_parse_steps_and_seed
    r = GenerateRequest.parse(["a cat", "--steps", "6", "--seed", "42"])
    assert_equal "6", r.steps
    assert_equal "42", r.seed
  end

  def test_parse_guidance
    assert_equal "5", GenerateRequest.parse(["a raccoon", "--guidance", "5"]).guidance
  end

  def test_editing_false_without_edit
    refute GenerateRequest.parse(["a cat"]).editing?
  end

  def test_editing_true_with_edit
    r = GenerateRequest.parse(["make it blue", "--edit", "img.png"])
    assert r.editing?
    assert_equal "img.png", r.edit
  end

  def test_binary_txt2img
    assert_equal "mflux-generate-flux2", GenerateRequest.parse(["a cat"]).binary
  end

  def test_binary_edit
    assert_equal "mflux-generate-flux2-edit", GenerateRequest.parse(["x", "--edit", "img.png"]).binary
  end

  def test_default_steps_txt2img
    assert_equal Config::DEFAULT_STEPS_TXT2IMG, GenerateRequest.parse(["a cat"]).default_steps
  end

  def test_default_steps_edit
    assert_equal Config::DEFAULT_STEPS_EDIT, GenerateRequest.parse(["x", "--edit", "img.png"]).default_steps
  end

  def test_final_prompt_with_style
    assert_equal "a cat, chalk lines", GenerateRequest.parse(["a cat"]).final_prompt("chalk lines")
  end

  def test_final_prompt_without_style
    assert_equal "a cat", GenerateRequest.parse(["a cat"]).final_prompt(nil)
  end

  def test_style_default_on_txt2img
    assert_equal :default, GenerateRequest.parse(["a cat"]).style
  end

  def test_bare_disables_style
    assert_nil GenerateRequest.parse(["a cat", "--bare"]).style
  end

  def test_lora_on_by_default
    r = GenerateRequest.parse(["a raccoon"])
    assert_equal Config::DEFAULT_LORA_STYLE, r.lora_style
    assert_equal Config::DEFAULT_LORA_SCALE, r.lora_scale
  end

  def test_no_lora_disables
    assert_nil GenerateRequest.parse(["a raccoon", "--no-lora"]).lora_style
  end

  def test_lora_style_override
    assert_equal "storyboard", GenerateRequest.parse(["a raccoon", "--lora-style", "storyboard"]).lora_style
  end

  def test_lora_scale_override
    assert_equal "0.6", GenerateRequest.parse(["a raccoon", "--lora-scale", "0.6"]).lora_scale
  end

  def test_lora_on_regardless_of_style
    assert_equal Config::DEFAULT_LORA_STYLE, GenerateRequest.parse(["a raccoon", "--style", "chalk"]).lora_style
    assert_equal Config::DEFAULT_LORA_STYLE, GenerateRequest.parse(["a raccoon", "--bare"]).lora_style
  end

  # On --edit the prose style stays off (it would corrupt the instruction),
  # but the style LoRA still applies — it tweaks weights, not the prompt text.
  def test_edit_suppresses_prose_style_but_keeps_lora_default
    r = GenerateRequest.parse(["make hat blue", "--edit", "x.png"])
    assert_nil r.style
    assert_equal Config::DEFAULT_LORA_STYLE, r.lora_style
  end

  def test_edit_no_lora_escapes_default
    r = GenerateRequest.parse(["make hat blue", "--edit", "x.png", "--no-lora"])
    assert_nil r.lora_style
  end

  # Prose style is always suppressed in edit, even when passed explicitly.
  def test_edit_ignores_explicit_style
    r = nil
    _out, err = capture_io do
      r = GenerateRequest.parse(["make hat blue", "--edit", "x.png", "--style", "chalk"])
    end
    assert_nil r.style
    assert_match(/--style is ignored in edit mode/, err)
  end

  def test_edit_explicit_lora_still_applies
    r = GenerateRequest.parse(["make hat blue", "--edit", "x.png", "--lora-style", "chalk"])
    assert_equal "chalk", r.lora_style
  end
end

class BuildCommandTest < Minitest::Test
  def cmd(argv = [], negative_prompt: nil, out_path: "output/output_001.png")
    r = GenerateRequest.parse(["a raccoon"] + argv)
    Generate.build_command(r, r.final_prompt(nil), out_path: out_path, negative_prompt: negative_prompt)
  end

  def test_txt2img_default_steps
    assert_includes cmd, "mflux-generate-flux2 "
    assert_includes cmd, "--steps 12"
  end

  def test_edit_default_steps
    result = cmd(["--edit", "output/output_001.png"], out_path: "output/output_002.png")
    assert_includes result, "mflux-generate-flux2-edit"
    assert_includes result, "--steps 8"
  end

  def test_custom_steps
    assert_includes cmd(["--steps", "20"]), "--steps 20"
  end

  def test_seed_included_when_set
    assert_includes cmd(["--seed", "99"]), "--seed 99"
  end

  def test_seed_omitted_when_nil
    refute_includes cmd, "--seed"
  end

  def test_includes_expected_flags
    result = cmd(["--steps", "12", "--seed", "42"])
    assert_includes result, "--model #{Config::IMAGE_MODEL}"
    assert_includes result, "--prompt a\\ raccoon"
    assert_includes result, "--steps 12"
    assert_includes result, "--seed 42"
    assert_includes result, "--output output/output_001.png"
  end

  def test_lora_flags_emitted
    result = cmd(["--lora-style", "illustration", "--lora-scale", "1.0"])
    assert_includes result, "--lora-style illustration"
    assert_includes result, "--lora-scales 1.0"
  end

  def test_lora_omitted_when_nil
    result = cmd(["--no-lora"])
    refute_includes result, "--lora-style"
    refute_includes result, "--lora-scales"
  end

  def test_lora_applies_to_edit
    result = cmd(["--edit", "output/output_001.png", "--lora-style", "illustration", "--lora-scale", "1.0"],
      out_path: "output/output_002.png")
    assert_includes result, "mflux-generate-flux2-edit"
    assert_includes result, "--lora-style illustration"
  end

  # --guidance is gated behind Config::GUIDANCE_SUPPORTED (off for klein).
  def with_guidance_supported(value)
    old = Config::GUIDANCE_SUPPORTED
    Config.send(:remove_const, :GUIDANCE_SUPPORTED)
    Config.const_set(:GUIDANCE_SUPPORTED, value)
    yield
  ensure
    Config.send(:remove_const, :GUIDANCE_SUPPORTED)
    Config.const_set(:GUIDANCE_SUPPORTED, old)
  end

  def test_guidance_omitted_when_unsupported
    with_guidance_supported(false) do
      refute_includes cmd(["--guidance", "7"]), "--guidance"
    end
  end

  def test_guidance_default_when_supported_and_nil
    with_guidance_supported(true) do
      assert_includes cmd, "--guidance #{Config::DEFAULT_GUIDANCE}"
    end
  end

  def test_guidance_custom_overrides_default_when_supported
    with_guidance_supported(true) do
      assert_includes cmd(["--guidance", "7"]), "--guidance 7"
    end
  end

  # --negative-prompt is gated behind Config::NEGATIVE_PROMPT_SUPPORTED.
  def with_negative_prompt_supported
    Config.send(:remove_const, :NEGATIVE_PROMPT_SUPPORTED)
    Config.const_set(:NEGATIVE_PROMPT_SUPPORTED, true)
    yield
  ensure
    Config.send(:remove_const, :NEGATIVE_PROMPT_SUPPORTED)
    Config.const_set(:NEGATIVE_PROMPT_SUPPORTED, false)
  end

  def test_negative_prompt_omitted_when_not_supported
    refute Config::NEGATIVE_PROMPT_SUPPORTED, "update test if flag changes"
    refute_includes cmd(negative_prompt: "bad stuff"), "--negative-prompt"
  end

  def test_negative_prompt_included_when_supported
    with_negative_prompt_supported do
      assert_includes cmd(negative_prompt: "bad stuff"), "--negative-prompt"
    end
  end

  def test_negative_prompt_omitted_when_nil_even_if_supported
    with_negative_prompt_supported do
      refute_includes cmd(negative_prompt: nil), "--negative-prompt"
    end
  end
end

class NextOutputPathTest < Minitest::Test
  def setup
    @dir = "output"
    @existing = Dir["#{@dir}/output_*.png"]
  end

  def teardown
    (Dir["#{@dir}/output_*.png"] - @existing).each { |f| File.delete(f) }
  end

  def test_starts_at_001_when_empty
    skip "output/ already has images" unless @existing.empty?
    assert_equal "output/output_001.png", Output.next_output_path
  end

  def test_increments_from_existing
    File.write("#{@dir}/output_998.png", "")
    assert_equal "output/output_999.png", Output.next_output_path
  end
end
