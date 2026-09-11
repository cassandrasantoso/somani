require "faraday"

class Llm
  # Speaks the OpenAI chat-completions API. Because that API is a de facto
  # standard, this one provider covers OpenAI, OpenRouter, Groq, Together,
  # and local servers (Ollama, vLLM, LM Studio) — set OPENAI_BASE_URL to
  # point at whichever one you want and OPENAI_MODEL to a model it serves.
  #
  # Embeddings are not implemented here: they stay on Gemini (see Llm's
  # class comment) so the scene vectors keep sharing one space.
  class OpenaiCompatibleProvider
    DEFAULT_BASE_URL = "https://api.openai.com/v1"
    DEFAULT_MODEL = "gpt-4o-mini"

    class << self
      def resolve_model(model)
        return primary_model if model.nil?
        return lite_model if model == :lite

        model
      end

      def primary_model
        ENV.fetch("OPENAI_MODEL", DEFAULT_MODEL)
      end

      def lite_model
        ENV.fetch("OPENAI_LITE_MODEL", primary_model)
      end

      def base_url
        ENV.fetch("OPENAI_BASE_URL", DEFAULT_BASE_URL)
      end

      def connection
        Faraday.new(url: base_url) do |faraday|
          faraday.request :json
          faraday.response :json
          faraday.request :retry, max: 2, interval: 1
          faraday.options.timeout = 120
          faraday.options.open_timeout = 10
        end
      end

      def generate_text(prompt, system_instruction: nil, parts: [], json: false, model: nil)
        messages = [{ role: "user", content: parts_to_content([{ text: prompt }, *parts]) }]
        messages.unshift(role: "system", content: system_instruction) if system_instruction

        body = chat_completion(messages, model: model, json: json)

        Result.new(text: body.dig("choices", 0, "message", "content").to_s.strip,
                   usage: usage_of(body), model: resolve_model(model))
      end

      def generate_conversation(contents, system_instruction: nil, model: nil, &)
        stream_conversation(contents, system_instruction: system_instruction, model: model, &)
      end

      # Yields each text delta; returns the full text with usage from the
      # final chunk (stream_options: { include_usage: true }).
      def stream_conversation(contents, system_instruction: nil, model: nil, &block)
        messages = contents.map do |content|
          { role: content[:role] == "model" ? "assistant" : "user",
            content: parts_to_content(content[:parts]) }
        end
        messages.unshift(role: "system", content: system_instruction) if system_instruction

        full = +""
        usage = {}

        connection.post("chat/completions") do |request|
          request.headers["Authorization"] = "Bearer #{ENV.fetch('OPENAI_API_KEY')}"
          request.body = { model: resolve_model(model), messages: messages,
                           stream: true, stream_options: { include_usage: true } }
          request.options.on_data = proc do |chunk, _|
            chunk.split("\n").each do |line|
              delta, chunk_usage, done = parse_sse_line(line)
              usage = usage.merge(chunk_usage) { |_key, old, new| new || old } if chunk_usage

              next if delta.nil? || delta.empty?
              next if done

              full << delta
              block.call(delta)
            end
          end
        end

        Result.new(text: full.strip, usage: usage, model: resolve_model(model))
      end

      # "data: {...}" → [delta_text, usage_hash, done?]
      def parse_sse_line(line)
        return [nil, nil, false] unless line.start_with?("data: ")

        payload = line.delete_prefix("data: ").strip
        return [nil, nil, true] if payload == "[DONE]"

        parsed = JSON.parse(payload)
        [parsed.dig("choices", 0, "delta", "content"), usage_of(parsed), false]
      rescue JSON::ParserError
        [nil, nil, false]
      end

      private

      def chat_completion(messages, model: nil, json: false)
        response = connection.post("chat/completions") do |request|
          request.headers["Authorization"] = "Bearer #{ENV.fetch('OPENAI_API_KEY')}"
          request.body = { model: resolve_model(model), messages: messages }
          request.body[:response_format] = { type: "json_object" } if json
        end

        response.body
      end

      # [{ text: "..." }, { inline_data: { mime_type:, data: } }] → the
      # OpenAI content shape: text parts and base64 image data URLs.
      def parts_to_content(parts)
        content = parts.filter_map do |part|
          next { type: "text", text: part[:text] } if part.key?(:text) && part[:text].present?

          inline = part[:inline_data]
          next if inline.nil?

          unless inline[:mime_type].to_s.start_with?("image/")
            raise ArgumentError, "OpenAI-compatible providers only accept image parts, got #{inline[:mime_type]}"
          end

          { type: "image_url", image_url: { url: "data:#{inline[:mime_type]};base64,#{inline[:data]}" } }
        end

        return content.first if content.size == 1 && content.first.key?(:type) && content.first[:type] == "text"

        content
      end

      def usage_of(body)
        usage = body.is_a?(Hash) ? body["usage"] : nil
        return {} if usage.nil?

        { prompt_tokens: usage["prompt_tokens"],
          completion_tokens: usage["completion_tokens"],
          total_tokens: usage["total_tokens"],
          cached_tokens: usage.dig("prompt_tokens_details", "cached_tokens") }
      end
    end
  end
end

Llm.register_provider "openai", Llm::OpenaiCompatibleProvider
