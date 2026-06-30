require "json"

# Stateless helpers for resolving named style presets into prompt text.
# Styles live in prompts/styles.json; each is a layer with a "positive" snippet
# (always appended to the prompt) and an optional "negative" snippet.
module Styles
  STYLES_PATH = File.join(__dir__, "..", "prompts", "styles.json")

  # Loads the styles.json catalog. Returns the parsed Hash of name => layer,
  # or an empty Hash if the file is missing.
  def self.load
    JSON.parse(File.read(STYLES_PATH))
  rescue Errno::ENOENT
    {}
  end

  DEFAULT = "illustration"

  # Resolved style: the merged positive and negative prompt snippets.
  Result = Struct.new(:positive, :negative)

  # Resolves one or more comma-separated style names into a Result.
  # `names` is a string like "illustration,character", or :default for the
  # default layer, or nil. Returns nil for nil input; aborts on unknown names.
  # The matched layers' positive/negative snippets are joined into one Result.
  def self.lookup(names = nil)
    return nil unless names
    names = DEFAULT if names == :default
    styles = load
    layers = names.split(",").map(&:strip).uniq
    unknown = layers - styles.keys
    abort("Unknown style(s): #{unknown.join(", ")}\nAvailable: #{styles.keys.join(", ")}") if unknown.any?
    Result.new(
      layers.map { |l| styles[l]["positive"] }.join(", "),
      layers.map { |l| styles[l]["negative"] }.compact.join(", ")
    )
  end
end
