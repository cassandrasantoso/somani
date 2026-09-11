# The single entry point for every LLM call in the app. Jobs and services
# never talk to a provider class directly — they call Llm.generate_text,
# Llm.stream_conversation, and so on, and the provider is chosen by the
# LLM_PROVIDER environment variable (see PROVIDERS.md for the full setup).
#
# Usage recording (LlmCall) happens here, so every provider is costed the
# same way. Embeddings are the one exception: they stay on Gemini whatever
# the chat provider is, because the scene vectors in Postgres live in
# gemini-embedding-001's space — switching would mean re-embedding the
# whole library.
class Llm
  Result = Struct.new(:text, :usage, :model, keyword_init: true)

  PROVIDERS = {}

  class << self
    def register_provider(name, provider)
      PROVIDERS[name.to_s] = provider
    end

    def provider_name
      ENV.fetch("LLM_PROVIDER", "gemini")
    end

    def provider
      PROVIDERS.fetch(provider_name) do
        raise ArgumentError, "Unknown LLM_PROVIDER #{provider_name.inspect}. Registered: #{PROVIDERS.keys.join(', ')}"
      end
    end

    def generate_text(prompt, system_instruction: nil, parts: [], json: false, model: nil)
      result = record_usage(model: model) do
        provider.generate_text(prompt, system_instruction: system_instruction, parts: parts, json: json, model: model)
      end

      result.text
    end

    def generate_conversation(contents, system_instruction: nil, model: nil)
      result = record_usage(model: model) do
        provider.generate_conversation(contents, system_instruction: system_instruction, model: model)
      end

      result.text
    end

    def stream_conversation(contents, system_instruction: nil, model: nil, &block)
      accumulated = +""

      result = record_usage(model: model, operation: "stream") do
        provider.stream_conversation(contents, system_instruction: system_instruction, model: model) do |delta|
          accumulated << delta
          block.call(delta, +accumulated.dup)
        end
      end

      result.text
    end

    def generate_json(prompt, symbolize_names: false, model: nil)
      text = generate_text(prompt, json: true, model: model)

      parse_json(text, symbolize_names: symbolize_names)
    end

    # Pinned to Gemini for vector-space compatibility — see the class comment.
    def embed(text)
      result = record_usage_with(Llm::GeminiProvider, "embed", nil) { Llm::GeminiProvider.embed(text) }

      result.text
    end

    private

    def record_usage(model: nil, operation: "generate", &)
      record_usage_with(provider, operation, model, &)
    end

    def record_usage_with(provider, operation, model)
      resolved = provider.resolve_model(model)
      started = monotonic_now
      result = yield

      log_call(result.model || resolved, operation, elapsed_ms(started), result.usage)
      result
    end

    def log_call(model, operation, duration_ms, usage)
      LlmCall.create!(
        model: model,
        operation: operation,
        duration_ms: duration_ms,
        **usage.symbolize_keys
      )
    rescue StandardError => e
      Rails.logger.warn("LlmCall logging failed: #{e.class}: #{e.message}")
    end

    def monotonic_now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def elapsed_ms(started)
      ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round
    end

    def parse_json(text, symbolize_names:)
      cleaned = text.to_s.gsub(/```(?:json)?/, "").strip
      match = cleaned[/\{.*\}/m] || cleaned[/\[[^\]]*\]/m]
      return nil if match.nil?

      JSON.parse(match, symbolize_names: symbolize_names)
    rescue JSON::ParserError
      Rails.logger.warn("Llm unparseable JSON: #{text.to_s.truncate(200)}")
      nil
    end
  end
end

# Eager registration: the facade is reached through Llm.generate_text and
# friends, which never name a provider constant — autoload would never pull
# these files in on its own. Rails' autoloader tolerates the relative
# requires here because each file defines a single namespaced constant.
require_relative "llm/gemini_provider"
require_relative "llm/openai_compatible_provider"
