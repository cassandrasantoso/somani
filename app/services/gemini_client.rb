require "gemini-ai"

class GeminiClient
  DEFAULT_MODEL = "gemini-2.5-flash"

  class << self
    def client(model: nil)
      resolved = model || ENV.fetch("GEMINI_MODEL", DEFAULT_MODEL)

      Gemini.new(
        credentials: {
          service: "generative-language-api",
          api_key: ENV.fetch("GEMINI_API_KEY")
        },
        options: { model: resolved }
      )
    end

    def generate_text(prompt, system_instruction: nil, parts: [], json: false)
      payload = { contents: [{ role: "user", parts: [{ text: prompt }, *parts] }] }
      payload[:system_instruction] = { parts: [{ text: system_instruction }] } if system_instruction
      payload[:generation_config] = { response_mime_type: "application/json" } if json

      client.generate_content(payload).dig("candidates", 0, "content", "parts", 0, "text").to_s.strip
    end

    def generate_conversation(contents, system_instruction: nil)
      payload = { contents: contents }
      payload[:system_instruction] = { parts: [{ text: system_instruction }] } if system_instruction

      client.generate_content(payload).dig("candidates", 0, "content", "parts", 0, "text").to_s.strip
    end

    def generate_conversation_json(contents, system_instruction: nil)
      payload = { contents: contents,
                  generation_config: { response_mime_type: "application/json" } }
      payload[:system_instruction] = { parts: [{ text: system_instruction }] } if system_instruction

      text = client.generate_content(payload).dig("candidates", 0, "content", "parts", 0, "text").to_s

      parse_json(text, symbolize_names: false)
    end

    def generate_json(prompt, symbolize_names: false)
      text = generate_text(prompt, json: true)

      parse_json(text, symbolize_names: symbolize_names)
    end

    private

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
