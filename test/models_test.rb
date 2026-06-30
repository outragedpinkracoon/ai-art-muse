require "minitest/autorun"
require "stringio"
require_relative "../lib/commands/models"

class ModelsTest < Minitest::Test
  # Runs `muse models` and returns everything it printed as one string.
  def output
    out = StringIO.new
    orig = $stdout
    $stdout = out
    Models.new([]).run
    out.string
  ensure
    $stdout = orig
  end

  def test_groups_required_and_optional
    text = output
    assert_includes text, "REQUIRED"
    assert_includes text, "OPTIONAL"
  end

  def test_lists_every_model_from_config
    text = output
    [Config::IMAGE_MODEL, Config::VISION_MODEL, Config::REGEN_MODEL, Config::BRAINSTORM_MODEL].each do |model|
      assert_includes text, model
    end
  end

  def test_maps_models_to_their_commands
    text = output
    # /o interpolates each pattern once and caches it — the model names are
    # constants, so there's no point rebuilding the regexp on every call.
    assert_match(/#{Regexp.escape(Config::IMAGE_MODEL)}\s+generate, edit/o, text)
    assert_match(/#{Regexp.escape(Config::REGEN_MODEL)}\s+regen, restyle/o, text)
    assert_match(/#{Regexp.escape(Config::BRAINSTORM_MODEL)}\s+brainstorm/o, text)
  end

  def test_only_the_image_model_sits_under_required
    required_block = output[/REQUIRED\n(.*?)\n\n/m, 1]
    assert_includes required_block, Config::IMAGE_MODEL
    refute_includes required_block, Config::VISION_MODEL
  end
end
