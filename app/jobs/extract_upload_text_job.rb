require "base64"

class ExtractUploadTextJob < ApplicationJob
  queue_as :default

  retry_on Faraday::TooManyRequestsError, wait: :polynomially_longer, attempts: 5
  discard_on ActiveJob::DeserializationError

  def perform(upload)
    upload.update!(extracted_text: extract_text(upload), extraction_status: :ready)

    GenerateUploadSummaryJob.perform_later(upload)
    upload.broadcast_word_picker
  rescue Faraday::TooManyRequestsError
    raise
  rescue StandardError => e
    Rails.logger.error("ExtractUploadTextJob upload=#{upload.id}: #{e.class}: #{e.message}")
    upload.update!(extraction_status: :failed)
    upload.broadcast_word_picker
  end

  private

  def extract_text(upload)
    file = upload.file

    GeminiClient.generate_text(
      extraction_prompt(upload),
      parts: [{ inline_data: { mime_type: file.content_type,
                               data: Base64.strict_encode64(file.download) } }]
    )
  end

  def extraction_prompt(upload)
    <<~PROMPT
      #{extraction_task(upload.media_type)}

      Return only the Japanese text itself, exactly as it appears, with no
      commentary, labels, headings, or explanation. Do not translate anything.
      If there is no Japanese in the file, return nothing at all.
    PROMPT
  end

  def extraction_task(media_type)
    case media_type
    when "photo"    then "Transcribe all Japanese text visible in this image."
    when "document" then "Extract all Japanese text content from this document."
    when "audio"    then "Transcribe the Japanese speech in this audio recording."
    else                 "Extract or transcribe any Japanese text or speech in this file."
    end
  end
end
