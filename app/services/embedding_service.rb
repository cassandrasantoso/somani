class EmbeddingService
  MODEL = Llm::GeminiProvider::EMBED_MODEL
  DIMENSIONS = Llm::GeminiProvider::EMBED_DIMENSIONS

  def self.generate(text)
    Llm.embed(text)
  end
end
