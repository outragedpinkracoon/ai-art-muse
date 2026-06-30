#!/usr/bin/env ruby
require_relative "../config"
require_relative "../ollama"
require_relative "../prompts"
require "shellwords"

CRITIQUE_USAGE = <<~USAGE
  Usage:
    muse critique image.png
    muse critique image.png --chat
    muse critique image.png --ask "your question"
    muse critique image_a.png image_b.png
USAGE

# Runs a single `muse critique` invocation. Four modes — compare / chat / ask /
# single — selected in #run from the parsed argv.
class Critique
  # `argv` is the command's raw arguments; parses out the --chat flag, the --ask
  # question, and the leftover image path(s).
  def initialize(argv)
    args = argv.dup
    @chat = args.delete("--chat")
    ask_idx = args.index("--ask")
    @ask = ask_idx ? args.slice!(ask_idx, 2).last : nil
    @images = args.reject { |a| a.start_with?("--") }
  end

  # Validates, then dispatches to compare / chat / ask / single critique based on
  # how many images and which flags were given. Prints the result.
  def run
    validate!

    if @images.length == 2
      puts "Comparing images..."
      puts diff_critique(@images[0], @images[1])
    elsif @chat
      chat_loop(@images[0], opening_question: @ask)
    elsif @ask
      puts "Asking..."
      puts critique_ask(@images[0], @ask)
    else
      puts "Critiquing..."
      puts critique(@images[0])
    end
  end

  private

  # Aborts with usage if no images or more than two were given, or with an error
  # if any named image doesn't exist.
  def validate!
    abort CRITIQUE_USAGE if @images.empty? || @images.length > 2
    @images.each do |img|
      abort "Image not found: #{img}" unless File.exist?(img)
    end
  end

  # Single-turn vision call — sends prompt + images, returns text response
  def vision_generate(prompt, image_paths)
    Ollama.generate(Config::VISION_MODEL, prompt, images: image_paths.map { |p| Ollama.encode_image(p) })
  end

  # Multi-turn chat call — sends full message history, image sent in first message only
  def vision_chat(messages)
    formatted = messages.map { |m| {role: m[:role], content: m[:content], images: m[:images]}.compact }
    Ollama.chat(Config::VISION_MODEL, formatted)
  end

  # Full structured critique using persona + critique format prompts
  def critique(image)
    vision_generate(Prompts.load_prompt("critique_persona.txt", "critique_prompt.txt"), [image])
  end

  # Compares two images and picks a favourite
  def diff_critique(image_a, image_b)
    base = Prompts.load_prompt("critique_persona.txt")
    prompt = base + <<~EXTRA

      You are now looking at two images. Compare them using the same values above.
      Tell me which you prefer and exactly why — be specific and direct.
      Format your response as:
      COMPARISON:
      <your comparison>
      WINNER:
      <which image (A or B) and a one-sentence reason>
    EXTRA
    vision_generate(prompt, [image_a, image_b])
  end

  # Answers a specific question about an image, skipping the structured format
  def critique_ask(image, question)
    base = Prompts.load_prompt("critique_persona.txt")
    prompt = base + "\n\nThe artist has a specific question. Answer it directly and concisely — no structure, no preamble:\n#{question}"
    vision_generate(prompt, [image])
  end

  # Interactive chat session — image loaded once, conversation continues until exit/done/quit
  def chat_loop(image, opening_question: nil)
    base = Prompts.load_prompt("critique_persona.txt", "critique_chat_prompt.txt")
    first_message = opening_question || "Take a look at this image. What do you think?"
    messages = [
      {
        role: "user",
        content: base + "\n\n" + first_message,
        images: [Ollama.encode_image(image)]
      }
    ]

    puts "Loading image...\n\n"
    response = vision_chat(messages)
    puts response
    messages << {role: "assistant", content: response}

    loop do
      print "\n> "
      input = $stdin.gets&.strip
      break if input.nil? || %w[done exit quit].include?(input.downcase)
      next if input.empty?

      messages << {role: "user", content: input}
      reply = vision_chat(messages)
      puts "\n#{reply}"
      messages << {role: "assistant", content: reply}
    end

    system("ollama stop #{Config::VISION_MODEL}")
    puts "\nChat ended."
  end
end
