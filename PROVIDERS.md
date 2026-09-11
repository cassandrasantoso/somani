# Switching LLM providers

Every AI call goes through one facade: `app/services/llm.rb`. Providers are
selected with the `LLM_PROVIDER` env var and registered at the bottom of
their class file.

## Swap the model (same provider)

```bash
GEMINI_MODEL=gemini-2.5-pro           # roleplay + review
GEMINI_LITE_MODEL=gemini-2.5-flash    # furigana, estimates, summaries, scenes
```

## Swap the provider

**Gemini (default):**
```bash
LLM_PROVIDER=gemini
GEMINI_API_KEY=...
```

**Any OpenAI-compatible API** (OpenAI, OpenRouter, Groq, Together, Ollama, vLLM, LM Studio):
```bash
LLM_PROVIDER=openai
OPENAI_API_KEY=...
OPENAI_BASE_URL=https://openrouter.ai/api/v1   # or http://localhost:11434/v1 for Ollama
OPENAI_MODEL=...
OPENAI_LITE_MODEL=...                          # optional; falls back to OPENAI_MODEL
```

## Adding a new provider

Create `app/services/llm/my_provider.rb` implementing:

| Method | Returns |
|---|---|
| `resolve_model(model)` | `nil` → primary, `:lite` → cheap model, else passthrough |
| `generate_text(prompt, system_instruction:, parts:, json:, model:)` | `Llm::Result` (text + usage) |
| `generate_conversation(contents, system_instruction:, model:)` | `Llm::Result` |
| `stream_conversation(contents, system_instruction:, model:) { \|delta\| }` | `Llm::Result` after yielding deltas |

Register it with `Llm.register_provider "my_provider", Llm::MyProvider`.
Usage logging (`LlmCall`) and JSON parsing are handled by the facade.

## Notes

- **Embeddings stay on Gemini** (`Llm.embed` always routes to the Gemini
  provider): the scene vectors in Postgres live in `gemini-embedding-001`'s
  space. Switching embedding provider means re-embedding the scene library.
- The OpenAI-compatible provider handles text and images; audio uploads
  raise a clear error and need the Gemini path.
- `bin/rails llm:usage` reports per-model costs, whichever provider is on.
