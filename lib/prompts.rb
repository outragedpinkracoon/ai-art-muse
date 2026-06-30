require_relative "ollama"

# Stateless helpers for loading prompt templates.
module Prompts
  def self.load_prompt(*files)
    files.map { |f| File.read(File.join(__dir__, "..", "prompts", f)) }.join("\n\n")
  end
end
