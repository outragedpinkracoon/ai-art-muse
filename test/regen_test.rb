require "minitest/autorun"
require_relative "../lib/commands/regen"

class RegenTest < Minitest::Test
  def image(c) = c.instance_variable_get(:@image)
  def subject(c) = c.instance_variable_get(:@subject)
  def passthrough(c) = c.instance_variable_get(:@passthrough)

  def test_parses_image_subject_and_passthrough
    c = Regen.new(["table.png", "a table with a plant", "--steps", "20"])
    assert_equal "table.png", image(c)
    assert_equal "a table with a plant", subject(c)
    assert_equal ["--steps", "20"], passthrough(c)
  end

  def test_empty_passthrough_when_none_given
    assert_empty passthrough(Regen.new(["table.png", "a plant"]))
  end

  # Subject is everything before the first comma; style is the rest.
  def test_style_block_is_everything_after_first_comma
    prompt = "a table, flat colors, bold ink outlines, no gradients"
    assert_equal "flat colors, bold ink outlines, no gradients", Regen.style_block(prompt)
  end

  def test_style_block_empty_when_no_comma
    assert_equal "", Regen.style_block("a table")
  end

  # The full style block is already in the prompt, so Generate must run --bare.
  def test_build_argv_passes_bare_and_seed
    argv = Regen.build_argv("a plant, flat colors", seed: 123, passthrough: [])
    assert_equal ["a plant, flat colors", "--bare", "--seed", "123"], argv
  end

  def test_build_argv_omits_seed_when_absent
    argv = Regen.build_argv("a plant, flat colors", seed: nil, passthrough: [])
    refute_includes argv, "--seed"
  end

  def test_build_argv_appends_passthrough
    argv = Regen.build_argv("a plant", seed: 1, passthrough: ["--steps", "20"])
    assert_equal ["--steps", "20"], argv.last(2)
  end

  def test_uses_dedicated_model
    refute_empty Config::REGEN_MODEL
  end

  def test_system_prompt_loads
    refute_empty Prompts.load_prompt("regen.txt")
  end
end
