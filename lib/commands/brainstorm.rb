#!/usr/bin/env ruby
require_relative "../config"
require_relative "../ollama"
require_relative "../prompts"

BRAINSTORM_USAGE = <<~USAGE
  Usage: muse brainstorm "your rough idea"
    e.g. muse brainstorm "a cat pirate"
USAGE

# Runs a single `muse brainstorm` invocation: an interactive loop where the text
# model asks focused visual questions, then emits a final Flux prompt.
class Brainstorm
  MAX_QUESTIONS = 5

  # `argv` is the command's raw arguments; the non-flag words join into the
  # rough idea seed.
  def initialize(argv)
    @seed = argv.reject { |a| a.start_with?("--") }.join(" ")
  end

  # Runs the brainstorm loop, or aborts with usage if no seed was given.
  def run
    abort BRAINSTORM_USAGE if @seed.empty?
    brainstorm_loop(@seed)
  end

  private

  # Sends the running message history to the text model and returns its reply.
  def brainstorm_chat(messages)
    Ollama.chat(Config::BRAINSTORM_MODEL, messages)
  end

  # Interactive loop: qwen asks focused visual questions one at a time, then emits
  # a final Flux prompt. Caps at MAX_QUESTIONS; the artist can finish early with `done`.
  def brainstorm_loop(seed)
    system_prompt = Prompts.load_prompt("brainstorm.txt")
    messages = [
      {role: "system", content: system_prompt},
      {role: "user", content: "My idea: #{seed}\n\nAsk me your first question."}
    ]

    puts "Idea: #{seed}"
    puts "(answer each question; type `done` anytime to finalize)\n\n"

    asked = 0
    loop do
      reply = brainstorm_chat(messages)
      messages << {role: "assistant", content: reply}
      asked += 1
      puts reply

      print "\n> "
      input = $stdin.gets&.strip
      break if input.nil? || %w[done exit quit].include?(input.downcase)
      messages << {role: "user", content: input.empty? ? "(no preference — your call)" : input}

      break if asked >= MAX_QUESTIONS
    end

    messages << {role: "user", content: "Now finalize. Output only the Flux prompt."}
    final = brainstorm_chat(messages)

    system("ollama stop #{Config::BRAINSTORM_MODEL}")
    puts "\n#{"-" * 60}\nFinal Flux prompt:\n\n#{final}\n\nRun it:\n  muse generate #{final.inspect}"
  end
end
