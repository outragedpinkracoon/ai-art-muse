#!/usr/bin/env ruby
require_relative "../config"
require_relative "../ollama"
require_relative "../prompts"

IMAGINE_USAGE = <<~USAGE
  Usage: muse imagine "your rough idea"
    e.g. muse imagine "a cat pirate"
USAGE

# Runs a single `muse imagine` invocation: an interactive loop where the text
# model asks focused visual questions, then emits a final Flux prompt.
class Imagine
  MAX_QUESTIONS = 5

  # `argv` is the command's raw arguments; the non-flag words join into the
  # rough idea seed.
  def initialize(argv)
    @seed = argv.reject { |a| a.start_with?("--") }.join(" ")
  end

  # Runs the imagine loop, or aborts with usage if no seed was given.
  def run
    abort IMAGINE_USAGE if @seed.empty?
    imagine_loop(@seed)
  ensure
    # Free the model no matter how the loop ended (finished, crashed, ^C), so a
    # crash never leaves it resident (smoke runs models one at a time).
    system("ollama stop #{Config::IMAGINE_MODEL}", out: File::NULL, err: File::NULL)
  end

  private

  # Sends the running message history to the text model and returns its reply.
  def imagine_chat(messages)
    Ollama.chat(Config::IMAGINE_MODEL, messages)
  end

  # Interactive loop: qwen asks focused visual questions one at a time, then emits
  # a final Flux prompt. Caps at MAX_QUESTIONS; the artist can finish early with `done`.
  def imagine_loop(seed)
    system_prompt = Prompts.load_prompt("imagine.txt")
    messages = [
      {role: "system", content: system_prompt},
      {role: "user", content: "My idea: #{seed}\n\nAsk me your first question."}
    ]

    puts "Idea: #{seed}"
    puts "(answer each question; type `done` anytime to finalize)\n\n"

    asked = 0
    loop do
      reply = imagine_chat(messages)
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
    final = imagine_chat(messages)

    puts "\n#{"-" * 60}\nFinal Flux prompt:\n\n#{final}\n\nRun it:\n  muse generate #{final.inspect}"
  end
end
