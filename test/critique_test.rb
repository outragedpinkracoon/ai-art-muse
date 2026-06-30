require "minitest/autorun"
require_relative "../lib/commands/critique"

class CritiqueParsingTest < Minitest::Test
  def images(c) = c.instance_variable_get(:@images)

  def ask(c) = c.instance_variable_get(:@ask)

  def chat(c) = c.instance_variable_get(:@chat)

  def test_parses_chat_flag
    c = Critique.new(["image.png", "--chat"])
    assert chat(c)
    assert_equal ["image.png"], images(c)
  end

  def test_parses_ask_flag
    c = Critique.new(["image.png", "--ask", "is the focal point working?"])
    assert_equal "is the focal point working?", ask(c)
    assert_equal ["image.png"], images(c)
  end

  def test_parses_two_images
    c = Critique.new(["image_a.png", "image_b.png"])
    assert_equal 2, images(c).length
  end

  def test_no_ask_returns_nil
    assert_nil ask(Critique.new(["image.png"]))
  end

  def test_no_chat_returns_nil
    assert_nil chat(Critique.new(["image.png"]))
  end
end
