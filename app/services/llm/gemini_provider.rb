require "gemini-ai"

class Llm
  # The default provider. Model selection comes from GEMINI_MODEL and
  # GEMINI_LITE_MODEL; mechanical calls pass model: :lite.
  class GeminiProvider
    # Defaults proven against the current API (September 2026): this model
    # family is what fresh keys resolve. GEMINI_MODEL / GEMINI_LITE_MODEL
    # override both — raise them for a heavier tier if the key allows it.
    DEFAULT_MODEL = "gemini-3.1-flash-lite"
    LITE_MODEL = "gemini-3.1-flash-lite"
    EMBED_MODEL = "gemini-embedding-001"
    EMBED_DIMENSIONS = 768
    REQUEST_TIMEOUT = 120

    class << self
      def resolve_model(model)
        return primary_model if model.nil?
        return lite_model if model == :lite

        model
      end

      def primary_model
        ENV.fetch("GEMINI_MODEL", DEFAULT_MODEL)
      end

      def lite_model
        ENV.fetch("GEMINI_LITE_MODEL", LITE_MODEL)
      end

      def client(model: nil)
        Gemini.new(
          credentials: {
            service: "generative-language-api",
            api_key: ENV.fetch("GEMINI_API_KEY")
          },
          options: {
            model: resolve_model(model),
            connection: { request: { timeout: REQUEST_TIMEOUT, open_timeout: 10 } }
          }
        )
      end

      def generate_text(prompt, system_instruction: nil, parts: [], json: false, model: nil)
        payload = { contents: [{ role: "user", parts: [{ text: prompt }, *parts] }] }
        payload[:system_instruction] = { parts: [{ text: system_instruction }] } if system_instruction
        payload[:generation_config] = { response_mime_type: "application/json" } if json

        response = client(model: model).generate_content(payload)

        Result.new(text: response.dig("candidates", 0, "content", "parts", 0, "text").to_s.strip,
                   usage: usage_of(response), model: resolve_model(model))
      end

      def generate_conversation(contents, system_instruction: nil, model: nil)
        payload = { contents: contents }
        payload[:system_instruction] = { parts: [{ text: system_instruction }] } if system_instruction

        response = client(model: model).generate_content(payload)

        Result.new(text: response.dig("candidates", 0, "content", "parts", 0, "text").to_s.strip,
                   usage: usage_of(response), model: resolve_model(model))
      end

      # Yields each text delta; returns the full text with usage from the
      # final chunk (Gemini puts usageMetadata on the last stream event).
      def stream_conversation(contents, system_instruction: nil, model: nil, &block)
        payload = { contents: contents }
        payload[:system_instruction] = { parts: [{ text: system_instruction }] } if system_instruction

        full = +""
        usage = nil

        client.stream_generate_content(payload, server_sent_events: true) do |event, _parsed, _raw|
          usage = event["usageMetadata"] if event.is_a?(Hash) && event["usageMetadata"]

          delta = event.dig("candidates", 0, "content", "parts", 0, "text").to_s
          next if delta.empty?

          full << delta
          block.call(delta)
        end

        Result.new(text: full.strip, usage: usage_of_hash(usage), model: resolve_model(model))
      end

      def embed(text)
        response = client(model: EMBED_MODEL).embed_content(
          {
            content: { parts: [{ text: text }] },
            output_dimensionality: EMBED_DIMENSIONS
          }
        )

        Result.new(text: response.dig("embedding", "values"), usage: usage_of(response), model: EMBED_MODEL)
      end

      private

      def usage_of(response)
        usage_of_hash(response.is_a?(Hash) ? response["usageMetadata"] : nil)
      end

      def usage_of_hash(meta)
        return {} if meta.nil?

        { prompt_tokens: meta["promptTokenCount"],
          completion_tokens: meta["candidatesTokenCount"],
          total_tokens: meta["totalTokenCount"],
          cached_tokens: meta["cachedContentTokenCount"] }
      end
    end
  end
end

Llm.register_provider "gemini", Llm::GeminiProvider
