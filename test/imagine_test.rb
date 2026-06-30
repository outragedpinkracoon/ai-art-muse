require "minitest/autorun"
require_relative "../lib/commands/imagine"

class ImagineTest < Minitest::Test
  def seed(c) = c.instance_variable_get(:@seed)

  def test_max_questions_is_capped
    assert_equal 5, Imagine::MAX_QUESTIONS
  end

  def test_uses_dedicated_model
    refute_empty Config::IMAGINE_MODEL
  end

  def test_system_prompt_loads
    refute_empty Prompts.load_prompt("imagine.txt")
  end

  def test_parses_seed_dropping_flags
    assert_equal "a cat pirate", seed(Imagine.new(["a cat pirate", "--whatever"]))
  end

  def test_empty_seed_when_no_args
    assert_empty seed(Imagine.new([]))
  end
end
