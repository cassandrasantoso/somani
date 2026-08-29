require "gemini-ai"

class ReviewMessageJob < ApplicationJob
  queue_as :default

  # Same pattern as GenerateUploadSummaryJob — a rate-limited feedback pass is
  # worth retrying later, not worth failing loudly.
  retry_on Faraday::TooManyRequestsError, wait: :polynomially_longer, attempts: 5
  discard_on ActiveJob::DeserializationError

  # Short acknowledgements have nothing to correct. Grading 「はい」 to say
  # "looks good" teaches the learner that the marker means nothing.
  MIN_LENGTH = 10

  def perform(message)
    return unless message.role == "user"
    return if message.adventure.draft? # no scene yet — see note below
    return if message.feedback.present?
    return if message.body.to_s.strip.length < MIN_LENGTH

    data = parse(raw_response(message))
    return if data.blank?

    message.create_feedback!(
      assessment: data["assessment"].to_s.strip.presence,
      level_estimate: data["level_estimate"].to_s.strip.presence,
      corrections: sanitize(data["corrections"])
    )

    broadcast(message)
  rescue Faraday::TooManyRequestsError
    raise # let retry_on handle it
  rescue StandardError => e
    Rails.logger.warn("ReviewMessageJob #{message.id}: #{e.class}: #{e.message}")
  end

  private

  # Everything off a model is untrusted: cap at 3 even if the prompt is
  # ignored, drop malformed rows, and never let an unknown kind reach a CSS
  # class name.
  def sanitize(raw)
    Array(raw).first(3).filter_map do |c|
      next unless c.is_a?(Hash) && c["wrote"].present? && c["better"].present?

      { "kind" => Feedback::KINDS.include?(c["kind"]) ? c["kind"] : "grammar",
        "wrote" => c["wrote"].to_s,
        "better" => c["better"].to_s,
        "why" => c["why"].to_s }
    end
  end

  def raw_response(message)
    response = gemini_client.generate_content(
      { contents: [{ role: "user", parts: [{ text: prompt(message) }] }] }
    )
    response.dig("candidates", 0, "content", "parts", 0, "text").to_s
  end

  def parse(text)
    cleaned = text.gsub(/```(?:json)?/, "").strip
    match   = cleaned[/\{.*\}/m]
    match ? JSON.parse(match) : nil
  rescue JSON::ParserError
    Rails.logger.warn("ReviewMessageJob unparseable: #{text.truncate(200)}")
    nil
  end

  def broadcast(message)
    message.broadcast_replace_to(
      message.adventure,
      target: ActionView::RecordIdentifier.dom_id(message, :feedback),
      partial: "feedbacks/feedback",
      locals: { message: message }
    )
  end

  def gemini_client
    Gemini.new(
      credentials: { service: "generative-language-api",
                     api_key: ENV.fetch("GEMINI_API_KEY") },
      options: { model: ENV.fetch("GEMINI_MODEL") }
    )
  end
end
