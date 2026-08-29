require "gemini-ai"

class GenerateWordExplanationJob < ApplicationJob
  queue_as :default

  retry_on Faraday::TooManyRequestsError, wait: :polynomially_longer, attempts: 5

  def perform(saved_word)
    return if saved_word.explanation.present?

    saved_word.update!(explanation: generate_explanation(saved_word))
  end

  private

  def generate_explanation(word)
    prompt = <<~PROMPT
      You are helping a Japanese language learner understand a word or grammar point
      they just saved while studying.

      Word/phrase: #{word.surface}
      Reading: #{word.reading}
      Short meaning: #{word.meaning}
      JLPT level: #{word.level}

      Write a short, beginner-friendly explanation in English covering:
      - What it means and any nuance a short dictionary definition would miss
      - One natural example sentence in Japanese using it, followed by its English translation
      - Any easily confused words or common mistakes, if relevant

      Requirements:
      - 3-5 sentences total, plain text (no markdown, no headers)
      - Keep it encouraging and easy for a learner to follow
    PROMPT

    response = gemini_client.generate_content({
                                                contents: [
                                                  {
                                                    role: "user",
                                                    parts: [
                                                      { text: prompt }
                                                    ]
                                                  }
                                                ]
                                              })

    response
      .dig("candidates", 0, "content", "parts", 0, "text")
      .to_s
      .strip
  end

  def gemini_client
    Gemini.new(
      credentials: {
        service: "generative-language-api",
        api_key: ENV.fetch("GEMINI_API_KEY")
      },
      options: { model: ENV.fetch("GEMINI_MODEL") }
    )
  end
end
