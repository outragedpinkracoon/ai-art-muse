# Central constants for the toolchain: Ollama endpoint, model names, and the
# mflux generation defaults. Edit here to retarget models or shift defaults;
# nothing else hard-codes these values.
module Config
  OLLAMA_URL = "http://localhost:11434"
  VISION_MODEL = "qwen3-vl:8b"
  # Per-request context window for Ollama calls (critique, chat, imagine). Set
  # explicitly so we don't depend on the Ollama server default (the desktop
  # app's UI slider), which silently overrides any OLLAMA_CONTEXT_LENGTH env
  # var. 32k gives headroom for image tokens + prompt + a multi-turn session
  # without wasting KV cache RAM.
  OLLAMA_NUM_CTX = 32768
  IMAGINE_MODEL = "gemma4:e4b-mlx"
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
