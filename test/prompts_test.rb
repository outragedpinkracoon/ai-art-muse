require "minitest/autorun"
require_relative "../lib/prompts"

class LoadPromptTest < Minitest::Test
  def test_loads_single_file
    content = Prompts.load_prompt("critique_persona.txt")
    refute_empty content
  end

  def test_loads_and_concatenates_multiple_files
    content = Prompts.load_prompt("critique_persona.txt", "critique_prompt.txt")
    assert_includes content, "\n\n"
  end

  def test_raises_on_missing_file
    assert_raises(Errno::ENOENT) { Prompts.load_prompt("nonexistent.txt") }
  end
end
