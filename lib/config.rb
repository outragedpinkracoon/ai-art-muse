# Central constants for the toolchain: Ollama endpoint, model names, and the
# mflux generation defaults. Edit here to retarget models or shift defaults;
# nothing else hard-codes these values.
module Config
  OLLAMA_URL = "http://localhost:11434"
  VISION_MODEL = "qwen2.5vl:7b"
  IMAGINE_MODEL = "hf.co/yuxinlu1/gemma-4-12B-it-Claude-4.6-4.8-Opus-GGUF:Q4_K_M"
  # Small text model for the regen subject/style fuse — a constrained rewrite,
  # so a fast 3B is plenty (no need for the heavier imagine model).
  REGEN_MODEL = "qwen2.5:3b"
  IMAGE_MODEL = "flux2-klein-4b"
  DEFAULT_STEPS_TXT2IMG = "12"
  DEFAULT_STEPS_EDIT = "8"
  DEFAULT_GUIDANCE = "3.5"
  # Built-in mflux style LoRA, always applied unless --no-lora.
  # Carries the chalk/noir look that prose alone can't on guidance-free Klein.
  DEFAULT_LORA_STYLE = "illustration"
  DEFAULT_LORA_SCALE = "1.0"
  # Distilled models (klein) lock guidance at 1.0 and reject --guidance.
  # Flip to true when switching to a FLUX.2 base model.
  GUIDANCE_SUPPORTED = false
  NEGATIVE_PROMPT_SUPPORTED = false
end
