require "minitest/autorun"
require_relative "../lib/commands/restyle"

class RestyleTest < Minitest::Test
  def image(c) = c.instance_variable_get(:@image)
  def passthrough(c) = c.instance_variable_get(:@passthrough)

  def test_parses_image_and_passthrough
    c = Restyle.new(["rabbit.png", "--style", "chalk", "--steps", "16"])
    assert_equal "rabbit.png", image(c)
    assert_equal ["--style", "chalk", "--steps", "16"], passthrough(c)
  end

  def test_empty_passthrough_when_none_given
    assert_empty passthrough(Restyle.new(["rabbit.png"]))
  end

  # The new style comes from --style, so Generate appends it; no --bare here
  # (unlike regen, whose style is already baked into the prompt).
  def test_build_argv_keeps_subject_seed_and_passthrough
    argv = Restyle.build_argv("a rabbit", seed: 123, passthrough: ["--style", "chalk"])
    assert_equal ["a rabbit", "--seed", "123", "--style", "chalk"], argv
  end

  def test_build_argv_omits_seed_when_absent
    argv = Restyle.build_argv("a rabbit", seed: nil, passthrough: ["--style", "chalk"])
    refute_includes argv, "--seed"
  end

  def test_uses_dedicated_model
    refute_empty Config::REGEN_MODEL
  end

  def test_system_prompt_loads
    refute_empty Prompts.load_prompt("restyle.txt")
  end
end
