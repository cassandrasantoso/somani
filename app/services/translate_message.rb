# app/services/translate_message.rb
require "gemini-ai"

class TranslateMessage
  def self.call(message)
    new(message).call
  end

  def initialize(message)
    @message = message
  end

  def call
    response = gemini_client.generate_content({
                                                contents: [
                                                  {
                                                    role: "user",
                                                    parts: [{ text: prompt }]
                                                  }
                                                ]
                                              })

    response.dig("candidates", 0, "content", "parts", 0, "text").to_s.strip
  end

  private

  attr_reader :message

  def prompt
    <<~PROMPT
      Translate the following Japanese text into natural, fluent English.
      Return ONLY the translation, with no commentary, quotation marks, or
      explanation.

      Japanese text:
      #{message.body}
    PROMPT
  end

  def gemini_client
    Gemini.new(
      credentials: {
        service: "generative-language-api",
        api_key: ENV.fetch("GEMINI_API_KEY")
      },
      options: { model: ENV.fetch("GEMINI_MODEL_LITE") }
    )
  end
end
