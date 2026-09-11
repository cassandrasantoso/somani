# app/jobs/generate_upload_summary_job.rb
class GenerateUploadSummaryJob < ApplicationJob
  queue_as :default

  retry_on Faraday::TooManyRequestsError, wait: :polynomially_longer, attempts: 5
  discard_on ActiveJob::DeserializationError

  def perform(upload)
    return if upload.extracted_text.blank?

    upload.update!(summary: GeminiClient.generate_text(summary_prompt(upload.extracted_text),
                                                       model: GeminiClient::LITE_MODEL))
    upload.broadcast_summary
    GenerateUploadSceneJob.perform_later(upload)
  end

  private

  def summary_prompt(text)
    <<~PROMPT
      Identify the main topic of the following Japanese text.

      Return exactly one English sentence using this format:
      Oh, it looks like you are reading about [topic]!

      Requirements:
      - Replace [topic] with a natural 3-to-6-word English topic
      - Keep the entire response on one line
      - Do not include brackets
      - Do not include quotation marks
      - Do not add explanations
      - Use only information found in the original text

      Japanese text:
      #{text}
    PROMPT
  end
end
