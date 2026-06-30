require "json"

# Stateless helpers for naming, writing, and reading image output + sidecars.
module Output
  # Where generated images land. Defaults to output/; MUSE_OUTPUT_DIR overrides it
  # so the smoke test can write into a throwaway dir it cleans up afterward.
  def self.output_dir
    ENV.fetch("MUSE_OUTPUT_DIR", "output")
  end

  def self.next_output_path
    dir = output_dir
    Dir.mkdir(dir) unless Dir.exist?(dir)
    existing = Dir["#{dir}/output_*.png"].map { |f| f[/\d+/].to_i }.max || 0
    "#{dir}/output_%03d.png" % (existing + 1)
  end

  def self.sidecar_json(image_path)
    image_path.sub(/\.[^.]+$/, ".json")
  end

  # mflux always embeds a full JSON blob (prompt, seed, steps, model, ...) in the
  # PNG's EXIF UserComment — no flag needed. (The optional --metadata sidecar is
  # written as `null` for flux2, so we extract from the image instead.)
  def self.extract_mflux_metadata(image_path)
    data = File.binread(image_path)
    m = data.match(/\{"mflux_version".*?\}/m)
    m && JSON.parse(m[0])
  rescue JSON::ParserError, Errno::ENOENT
    nil
  end

  # If two jobs run at once they both reserve the same output_NNN.png; mflux
  # resolves the collision by writing output_NNN_1.png for the loser. Resolve to
  # the file that actually landed so the sidecar isn't written for a missing path.
  def self.resolve_written_path(image_path)
    return image_path if File.exist?(image_path)
    base = image_path.sub(/\.[^.]+$/, "")
    ext = File.extname(image_path)
    Dir["#{base}_*#{ext}"].max || image_path
  end

  # Writes output_NNN.json next to the image with the run's metadata. Prefers the
  # mflux EXIF blob; falls back to what we know if extraction fails. Returns the
  # resolved image path (may differ from the requested one on a collision).
  #
  # mflux only records --lora-paths in its EXIF, never the named --lora-style, so
  # its lora_paths field is null even when a style LoRA ran. We pass the style/scale
  # we invoked with so the sidecar actually captures it.
  def self.write_sidecar(image_path, prompt:, mode:, source: nil, lora_style: nil, lora_scale: nil)
    image_path = resolve_written_path(image_path)
    meta = extract_mflux_metadata(image_path) || {"prompt" => prompt}
    meta["mode"] = mode
    meta["source"] = source if source
    meta["lora_style"] = lora_style
    meta["lora_scale"] = lora_style ? lora_scale : nil
    File.write(sidecar_json(image_path), JSON.pretty_generate(meta))
    image_path
  end
end
