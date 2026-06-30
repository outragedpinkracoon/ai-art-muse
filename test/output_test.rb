require "minitest/autorun"
require "tmpdir"
require_relative "../lib/output"

FIXTURE = File.join(__dir__, "fixtures", "sample_with_metadata.png")

class SidecarJsonTest < Minitest::Test
  def test_swaps_png_extension
    assert_equal "output/output_001.json", Output.sidecar_json("output/output_001.png")
  end
end

class ExtractMfluxMetadataTest < Minitest::Test
  def test_pulls_prompt_and_seed_from_png_exif
    meta = Output.extract_mflux_metadata(FIXTURE)
    assert_equal "a red cube on a table", meta["prompt"]
    assert_equal 42, meta["seed"]
    assert_equal "black-forest-labs/FLUX.2-klein-4B", meta["model"]
  end

  def test_returns_nil_when_no_metadata
    Dir.mktmpdir do |dir|
      plain = File.join(dir, "plain.png")
      File.binwrite(plain, "not a real png, no mflux blob")
      assert_nil Output.extract_mflux_metadata(plain)
    end
  end

  def test_returns_nil_for_missing_file
    assert_nil Output.extract_mflux_metadata("does/not/exist.png")
  end
end

class WriteSidecarTest < Minitest::Test
  def with_fixture_copy
    Dir.mktmpdir do |dir|
      img = File.join(dir, "output_001.png")
      File.binwrite(img, File.binread(FIXTURE))
      yield img
    end
  end

  def test_writes_json_sidecar_with_extracted_metadata
    with_fixture_copy do |img|
      Output.write_sidecar(img, prompt: "a red cube on a table", mode: "txt2img")
      meta = JSON.parse(File.read(Output.sidecar_json(img)))
      assert_equal "a red cube on a table", meta["prompt"]
      assert_equal 42, meta["seed"]
      assert_equal "txt2img", meta["mode"]
      refute meta.key?("source")
    end
  end

  def test_includes_source_for_edit_mode
    with_fixture_copy do |img|
      Output.write_sidecar(img, prompt: "add a hat", mode: "edit", source: "output/output_001.png")
      meta = JSON.parse(File.read(Output.sidecar_json(img)))
      assert_equal "edit", meta["mode"]
      assert_equal "output/output_001.png", meta["source"]
    end
  end

  def test_falls_back_to_prompt_when_no_exif
    Dir.mktmpdir do |dir|
      img = File.join(dir, "output_002.png")
      File.binwrite(img, "no mflux blob here")
      Output.write_sidecar(img, prompt: "fallback prompt", mode: "txt2img")
      meta = JSON.parse(File.read(Output.sidecar_json(img)))
      assert_equal "fallback prompt", meta["prompt"]
      assert_equal "txt2img", meta["mode"]
    end
  end

  # Concurrent jobs both reserve output_NNN.png; mflux writes output_NNN_1.png
  # for the loser. Output.write_sidecar must follow the file that actually landed.
  def test_resolves_to_mflux_collision_sibling
    Dir.mktmpdir do |dir|
      requested = File.join(dir, "output_001.png")
      landed = File.join(dir, "output_001_1.png")
      File.binwrite(landed, File.binread(FIXTURE)) # base never written, sibling did
      result = Output.write_sidecar(requested, prompt: "x", mode: "txt2img")
      assert_equal landed, result
      assert File.exist?(File.join(dir, "output_001_1.json"))
      refute File.exist?(File.join(dir, "output_001.json"))
    end
  end

  def test_prefers_exact_path_when_present
    with_fixture_copy do |img|
      assert_equal img, Output.write_sidecar(img, prompt: "x", mode: "txt2img")
    end
  end

  # mflux EXIF never records --lora-style, so we capture it ourselves.
  def test_records_lora_style_and_scale
    with_fixture_copy do |img|
      Output.write_sidecar(img, prompt: "x", mode: "txt2img", lora_style: "illustration", lora_scale: "1.0")
      meta = JSON.parse(File.read(Output.sidecar_json(img)))
      assert_equal "illustration", meta["lora_style"]
      assert_equal "1.0", meta["lora_scale"]
    end
  end

  def test_lora_fields_null_when_no_lora
    with_fixture_copy do |img|
      Output.write_sidecar(img, prompt: "x", mode: "txt2img")
      meta = JSON.parse(File.read(Output.sidecar_json(img)))
      assert_nil meta["lora_style"]
      assert_nil meta["lora_scale"]
    end
  end
end
