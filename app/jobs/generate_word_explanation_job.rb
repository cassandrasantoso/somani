class GenerateWordExplanationJob < ApplicationJob
  queue_as :default

  retry_on Faraday::TooManyRequestsError, wait: :polynomially_longer, attempts: 5
  discard_on ActiveJob::DeserializationError

  def perform(saved_word)
    return if saved_word.explanation.present?

    saved_word.update!(explanation: GeminiClient.generate_text(explanation_prompt(saved_word)))
  end

  private

  def explanation_prompt(word)
    <<~PROMPT
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
  end
end
