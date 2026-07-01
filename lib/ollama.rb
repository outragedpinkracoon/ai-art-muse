require "json"
require "net/http"
require_relative "config"

module Ollama
  # Single-turn completion. `model` is an Ollama model name, `prompt` the text,
  # `images` an optional array of base64-encoded images for a vision model.
  # Returns the model's stripped response string (nil if absent).
  def self.generate(model, prompt, images: nil, options: nil)
    body = {model: model, prompt: prompt, stream: false}
    body[:images] = images if images
    body[:options] = options if options
    post("#{Config::OLLAMA_URL}/api/generate", body)["response"]&.strip
  end

  # Multi-turn chat. `messages` is the role/content history array. Returns the
  # assistant's stripped reply string (nil if absent).
  def self.chat(model, messages, options: nil)
    body = {model: model, messages: messages, stream: false}
    body[:options] = options if options
    post("#{Config::OLLAMA_URL}/api/chat", body)
      .dig("message", "content")&.strip
  end

  # Reads an image file and returns its base64-encoded string, ready to pass as
  # an `images` entry to a vision model.
  def self.encode_image(path)
    # `pack("m0")` is strict base64 (no newlines), matching the old
    # Base64.strict_encode64 — vendored so the CLI needs no gems at runtime
    # (base64 left Ruby's default gems in 3.4).
    [File.binread(path)].pack("m0")
  end

  # POSTs `body` as JSON to `url` and returns the parsed JSON response Hash.
  # Long read_timeout because local model generation can be slow.
  def self.post(url, body)
    uri = URI(url)
    res = Net::HTTP.start(uri.host, uri.port, read_timeout: 300) do |http|
      http.post(uri.path, body.to_json, "Content-Type" => "application/json")
    end
    JSON.parse(res.body)
  end
end
