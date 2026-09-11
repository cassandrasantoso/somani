require "gemini-ai"

class GeminiClient
  DEFAULT_MODEL = "gemini-2.5-flash"
  # Mechanical work (furigana, level estimates, summaries, scenes) runs on a
  # ~3-6x cheaper model; quality-critical roleplay and review stay on flash.
  LITE_MODEL = "gemini-2.5-flash-lite"
  REQUEST_TIMEOUT = 120

  class << self
    def client(model: nil)
      resolved = model || ENV.fetch("GEMINI_MODEL", DEFAULT_MODEL)

      Gemini.new(
        credentials: {
          service: "generative-language-api",
          api_key: ENV.fetch("GEMINI_API_KEY")
        },
        options: {
          model: resolved,
          connection: { request: { timeout: REQUEST_TIMEOUT, open_timeout: 10 } }
        }
      )
    end

    def embed(text, model:)
      record_usage(model: model, operation: "embed") do
        client(model: model).embed_content(
          {
            content: { parts: [{ text: text }] },
            output_dimensionality: yield_dimensions(model)
          }
        )
      end
    end

    def generate_text(prompt, system_instruction: nil, parts: [], json: false, model: nil)
      payload = { contents: [{ role: "user", parts: [{ text: prompt }, *parts] }] }
      payload[:system_instruction] = { parts: [{ text: system_instruction }] } if system_instruction
      payload[:generation_config] = { response_mime_type: "application/json" } if json

      response = record_usage(model: model) { client(model: model).generate_content(payload) }

      response.dig("candidates", 0, "content", "parts", 0, "text").to_s.strip
    end

    def generate_conversation(contents, system_instruction: nil)
      payload = { contents: contents }
      payload[:system_instruction] = { parts: [{ text: system_instruction }] } if system_instruction

      response = record_usage { client.generate_content(payload) }

      response.dig("candidates", 0, "content", "parts", 0, "text").to_s.strip
    end

    def generate_conversation_json(contents, system_instruction: nil)
      payload = { contents: contents,
                  generation_config: { response_mime_type: "application/json" } }
      payload[:system_instruction] = { parts: [{ text: system_instruction }] } if system_instruction

      text = record_usage { client.generate_content(payload) }
             .dig("candidates", 0, "content", "parts", 0, "text").to_s

      parse_json(text, symbolize_names: false)
    end

    # Streams a multi-turn conversation. Yields (delta, accumulated_text) per
    # chunk and returns the full text. Falls over to the caller to rescue —
    # jobs fall back to generate_conversation when streaming fails.
    def stream_conversation(contents, system_instruction: nil)
      payload = { contents: contents }
      payload[:system_instruction] = { parts: [{ text: system_instruction }] } if system_instruction

      full = +""
      usage = nil
      started = monotonic_now

      client.stream_generate_content(payload, server_sent_events: true) do |event, _parsed, _raw|
        usage = event["usageMetadata"] if event.is_a?(Hash) && event["usageMetadata"]

        delta = event.dig("candidates", 0, "content", "parts", 0, "text").to_s
        next if delta.empty?

        full << delta
        yield(delta, +full.dup)
      end

      log_call(resolved_model, "stream", elapsed_ms(started), usage)

      full.strip
    end

    def generate_json(prompt, symbolize_names: false, model: nil)
      text = generate_text(prompt, json: true, model: model)

      parse_json(text, symbolize_names: symbolize_names)
    end

    private

    def yield_dimensions(model)
      model == "gemini-embedding-001" ? EmbeddingService::DIMENSIONS : nil
    end

    def resolved_model
      ENV.fetch("GEMINI_MODEL", DEFAULT_MODEL)
    end

    def record_usage(model: nil, operation: "generate")
      started = monotonic_now
      response = yield

      log_call(model || resolved_model, operation, elapsed_ms(started), usage_of(response))
      response
    end

    def usage_of(response)
      return {} unless response.is_a?(Hash)

      meta = response["usageMetadata"]
      return {} if meta.nil?

      { prompt_tokens: meta["promptTokenCount"],
        completion_tokens: meta["candidatesTokenCount"],
        total_tokens: meta["totalTokenCount"],
        cached_tokens: meta["cachedContentTokenCount"] }
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
      Rails.logger.warn("GeminiClient unparseable JSON: #{text.to_s.truncate(200)}")
      nil
    end
  end
end
