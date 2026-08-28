# app/jobs/generate_upload_summary_job.rb
require "gemini-ai"

class GenerateUploadSummaryJob < ApplicationJob
  queue_as :default

  retry_on Faraday::TooManyRequestsError, wait: :polynomially_longer, attempts: 5

  GEMINI_MODEL = "gemini-3.5-flash"

  def perform(upload)
    return if upload.extracted_text.blank?

    upload.update!(summary: generate_summary(upload.extracted_text))
  end

  private

  def generate_summary(text)
    prompt = <<~PROMPT
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
      options: { model: GEMINI_MODEL }
    )
  end
end
