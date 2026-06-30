require "minitest/autorun"
require "tmpdir"
require_relative "../lib/ollama"

class OllamaEncodeImageTest < Minitest::Test
  def test_round_trips_bytes_as_base64
    Dir.mktmpdir do |dir|
      path = File.join(dir, "img.bin")
      File.binwrite(path, "\x00\x01\x02hello")
      encoded = Ollama.encode_image(path)
      assert_equal "\x00\x01\x02hello".b, Base64.strict_decode64(encoded)
    end
  end
end

# generate/chat/post all hit Ollama over HTTP. We stub the one shared transport
# point (Ollama.post) so the request shaping and response parsing are exercised
# without a network or a running model.
class OllamaRequestShapingTest < Minitest::Test
  def test_generate_sends_prompt_and_returns_stripped_response
    captured = nil
    Ollama.stub(:post, ->(url, body) {
      captured = [url, body]
      {"response" => "  a tidy answer  "}
    }) do
      out = Ollama.generate("m", "draw a cat")
      assert_equal "a tidy answer", out
    end
    url, body = captured
    assert_includes url, "/api/generate"
    assert_equal "draw a cat", body[:prompt]
    refute body.key?(:images)
  end

  def test_generate_includes_images_when_given
    captured = nil
    Ollama.stub(:post, ->(_url, body) {
      captured = body
      {"response" => "ok"}
    }) do
      Ollama.generate("m", "p", images: ["b64data"])
    end
    assert_equal ["b64data"], captured[:images]
  end

  def test_chat_returns_stripped_message_content
    Ollama.stub(:post, ->(url, _body) {
      assert_includes url, "/api/chat"
      {"message" => {"content" => "  reply  "}}
    }) do
      assert_equal "reply", Ollama.chat("m", [{role: "user", content: "hi"}])
    end
  end

  def test_chat_returns_nil_when_no_content
    Ollama.stub(:post, ->(_url, _body) { {} }) do
      assert_nil Ollama.chat("m", [])
    end
  end
end
