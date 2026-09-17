class EmbeddingService
  MODEL = "gemini-embedding-001"
  DIMENSIONS = 768

  def self.generate(text)
    GeminiClient.client(model: MODEL).embed_content(
      {
        content: {
          parts: [
            { text: text }
          ]
        },
        output_dimensionality: DIMENSIONS
      }
    ).dig("embedding", "values")
  end
end
