require "gemini-ai"

class EmbeddingService
  MODEL = "gemini-embedding-001"
  DIMENSIONS = 768

  def self.generate(text)
    client = Gemini.new(
      credentials: {
        service: "generative-language-api",
        api_key: ENV.fetch("GEMINI_API_KEY")
      },
      options: {
        model: MODEL
      }
    )

    response = client.embed_content(
      {
        content: {
          parts: [
            { text: text }
          ]
        },
        output_dimensionality: DIMENSIONS
      }
    )

    response.dig("embedding", "values")
  end
end
