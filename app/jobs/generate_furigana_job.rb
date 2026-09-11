# Adds furigana readings to an assistant message after the fact, so the reply
# itself can stream as plain text and the readings arrive a beat later.
class GenerateFuriganaJob < ApplicationJob
  queue_as :default

  retry_on Faraday::TooManyRequestsError, wait: :polynomially_longer, attempts: 5
  discard_on ActiveJob::DeserializationError

  def perform(message)
    return if message.furigana.present?
    return unless message.role == "assistant" && message.body.present?

    data = GeminiClient.generate_json(prompt(message))
    segments = valid_segments(data, message.body.to_s.strip)
    return if segments.nil?

    message.update!(furigana: segments)

    message.broadcast_replace_to(
      message.adventure,
      target: ActionView::RecordIdentifier.dom_id(message, :row),
      partial: "messages/message",
      locals: { message: message }
    )
  end

  private

  # [{"base" => "今日", "reading" => "きょう"}, {"base" => "は"}] — or nil when
  # the response isn't a usable segment list, leaving the plain text in place.
  def valid_segments(data, body)
    return nil unless data.is_a?(Hash) && data["segments"].is_a?(Array)

    segments = data["segments"].filter_map do |segment|
      next unless segment.is_a?(Hash) && segment["base"].is_a?(String) && segment["base"].present?

      { "base" => segment["base"], "reading" => segment["reading"].to_s.presence }
    end

    return nil if segments.empty?

    joined = segments.map { |s| s["base"] }.join
    return nil unless joined == body

    segments
  end

  def prompt(message)
    <<~PROMPT
      Add furigana readings to this Japanese text:

      #{message.body}

      Return only JSON in exactly this shape:
      {"segments": [{"base": "今日", "reading": "きょう"}, {"base": "は"}]}

      Segment rules:
      - Concatenated in order, the base values must form the complete text
        exactly, character for character.
      - A segment with kanji in it carries that chunk's kana reading.
        Runs of plain kana, punctuation and numbers have no reading (null).
      - Keep segments short: never merge two words into one segment.
      - Readings are hiragana, or katakana when the base itself is katakana.
    PROMPT
  end
end
