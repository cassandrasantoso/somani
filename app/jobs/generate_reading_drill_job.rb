class GenerateReadingDrillJob < ApplicationJob
  queue_as :default

  retry_on Faraday::TooManyRequestsError, wait: :polynomially_longer, attempts: 5
  discard_on ActiveJob::DeserializationError

  # One-time per upload: split the extracted text into passages and ask the
  # lite model for comprehension questions per passage. After this, drills
  # on the same passages are free — no API call per practice run.
  def perform(upload)
    return if upload.extracted_text.blank?

    ReadingPassage.transaction do
      upload.reading_passages.destroy_all

      ReadingPassage.split_into_passages(upload.extracted_text).each_with_index do |text, index|
        questions = generate_questions(text)
        upload.reading_passages.create!(
          text: text, position: index + 1,
          char_count: text.length, questions: questions
        )
      end
    end

    upload.broadcast_reading_drill
  rescue Faraday::TooManyRequestsError
    raise
  rescue StandardError => e
    Rails.logger.warn("GenerateReadingDrillJob upload=#{upload.id}: #{e.class}: #{e.message}")
  end

  private

  def generate_questions(text)
    data = Llm.generate_json(questions_prompt(text), model: :lite)
    return [] unless data.is_a?(Hash) && data["questions"].is_a?(Array)

    data["questions"].filter_map do |question|
      next unless question.is_a?(Hash) && question["q"].present?
      next unless question["options"].is_a?(Array) && question["options"].size == 4
      next unless question["answer"].is_a?(Integer) && question["answer"].between?(0, 3)

      { "q" => question["q"].to_s,
        "options" => question["options"].map(&:to_s),
        "answer" => question["answer"],
        "kind" => %w[main_idea detail vocab].include?(question["kind"]) ? question["kind"] : "detail" }
    end.first(5)
  end

  def questions_prompt(text)
    <<~PROMPT
      You write comprehension checks for a Japanese speed-reading drill.
      A learner will read the passage below as fast as they can, then answer.

      Passage:
      #{text}

      Write exactly 3 multiple-choice questions in English about the passage:
      - one main_idea question (what the passage is about)
      - one detail question (a specific fact stated in it)
      - one vocab question (the meaning of a Japanese word or phrase from it, in this context)

      Return only JSON:
      {"questions": [{"q": "question text", "options": ["a", "b", "c", "d"], "answer": 0, "kind": "main_idea"}]}

      Rules:
      - Exactly 4 options per question, exactly one correct, "answer" is its index
      - Questions must be answerable from the passage alone
      - Plain English, no markdown
    PROMPT
  end
end
