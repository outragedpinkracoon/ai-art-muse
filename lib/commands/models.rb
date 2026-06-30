#!/usr/bin/env ruby
require_relative "../config"

# Runs `muse models`: prints the configured models — what each is, whether it's
# required, and which commands it powers — so you can see what's set and what to
# pull. The single source is lib/config.rb; nothing else hardcodes these names.
class Models
  # [Config constant, commands it unlocks]. Only the image model is required to
  # run muse at all; the Ollama models each just unlock an optional command.
  REQUIRED = [[Config::IMAGE_MODEL, ["generate", "edit"]]]
  OPTIONAL = [
    [Config::VISION_MODEL, ["critique"]],
    [Config::REGEN_MODEL, ["regen", "restyle"]],
    [Config::BRAINSTORM_MODEL, ["brainstorm"]]
  ]

  def initialize(argv)
    @argv = argv
  end

  def run
    puts "Models muse uses (configured in lib/config.rb):\n\n"

    puts "  REQUIRED"
    print_rows(REQUIRED)

    puts "\n  OPTIONAL  (pull only what you want; each unlocks its commands)"
    print_rows(OPTIONAL)
  end

  private

  # Prints "    <model>   <commands>" rows, the command column aligned to the
  # widest model name across both groups so they line up together.
  def print_rows(rows)
    width = (REQUIRED + OPTIONAL).map { |model, _| model.length }.max
    rows.each do |model, commands|
      puts "    #{model.ljust(width)}   #{commands.join(", ")}"
    end
  end
end
