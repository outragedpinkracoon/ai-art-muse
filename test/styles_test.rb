require "minitest/autorun"
require_relative "../lib/styles"

class StylesLookupTest < Minitest::Test
  def test_nil_returns_nil
    assert_nil Styles.lookup(nil)
  end

  def test_default_sentinel_gives_illustration
    result = Styles.lookup(:default)
    assert_includes result.positive, "Loose hand-drawn illustration"
    refute_includes result.positive, "Goofy deadpan expression"
    refute_includes result.positive, "felt-tip marker art"
  end

  def test_illustration_only
    result = Styles.lookup("illustration")
    assert_includes result.positive, "Loose hand-drawn illustration"
    refute_includes result.positive, "dark charcoal background"
  end

  def test_sketch_only
    result = Styles.lookup("sketch")
    assert_includes result.positive, "felt-tip marker art"
    refute_includes result.positive, "Goofy deadpan expression"
    refute_includes result.positive, "dark charcoal background"
  end

  def test_chalk_character_compose
    result = Styles.lookup("chalk,character")
    assert_includes result.positive, "dark charcoal background"
    assert_includes result.positive, "Goofy deadpan expression"
    refute_includes result.positive, "felt-tip marker art"
  end

  def test_sketch_object_compose
    result = Styles.lookup("sketch,object")
    assert_includes result.positive, "felt-tip marker art"
    assert_includes result.positive, "boxy blocky geometric shapes"
    refute_includes result.positive, "Goofy deadpan expression"
  end

  def test_chalk_object_compose
    result = Styles.lookup("chalk,object")
    assert_includes result.positive, "dark charcoal background"
    assert_includes result.positive, "boxy blocky geometric shapes"
  end

  def test_negative_prompt_populated
    result = Styles.lookup("sketch,character")
    refute_nil result.negative
    refute_empty result.negative
  end

  def test_unknown_layer_aborts
    capture_io do
      assert_raises(SystemExit) { Styles.lookup("badlayer") }
    end
  end

  def test_whitespace_around_layer_names_tolerated
    result = Styles.lookup("sketch, character")
    assert_includes result.positive, "felt-tip marker art"
    assert_includes result.positive, "Goofy deadpan expression"
  end
end
