# app/jobs/extract_content_job.rb
require "gemini-ai"
require "base64"

class ExtractContentJob < ApplicationJob
  queue_as :default

  GEMINI_MODEL = "gemini-2.5-flash"

  def perform(upload)
    text = extract_text(upload)
    upload.update!(extracted_text: text)
  end

  private

  def extract_text(upload)
    file = upload.file
    data = Base64.strict_encode64(file.download)

    response = gemini_client.generate_content({
                                                contents: [
                                                  {
                                                    role: "user",
                                                    parts: [
                                                      { text: prompt_for(upload.media_type) },
                                                      {
                                                        inline_data: {
                                                          mime_type: file.content_type,
                                                          data: data
                                                        }
                                                      }
                                                    ]
                                                  }
                                                ]
                                              })

    response.dig("candidates", 0, "content", "parts", 0, "text").to_s.strip
  end

  def prompt_for(media_type)
    case media_type
    when "photo"
      "Extract and transcribe any Japanese text visible in this image, exactly as written. Return only the extracted text, no commentary."
    when "document"
      "Extract the Japanese text content of this document, exactly as written. Return only the extracted text, no commentary."
    when "audio"
      "Transcribe the Japanese speech in this audio accurately. Return only the transcript, no commentary."
    end
  end

  def gemini_client
    Gemini.new(
      credentials: {
        service: "generative-language-api",
        api_key: ENV.fetch("GEMINI_API_KEY")
      },
      options: { model: GEMINI_MODEL }
    )
  end
end
