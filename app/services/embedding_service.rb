class EmbeddingService
  MODEL = "gemini-embedding-001"
  DIMENSIONS = 768

  def self.generate(text)
    GeminiClient.embed(text, model: MODEL).dig("embedding", "values")
  end
end
