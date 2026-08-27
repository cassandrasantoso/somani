class Scene < ApplicationRecord
  belongs_to :character
  has_neighbors :embedding
  has_many :adventures, dependent: :restrict_with_error

  DEFAULT_LEVEL = "N2".freeze

  # Orders scenes so ones matching the relevant JLPT level come first.
  # Prefers the level of words saved from this specific upload; falls back
  # to the user's overall saved_words history, then to N2 (the app's target level).
  def self.nearest_to_words(words)
    text = words.map(&:surface).join(" ")

    query_embedding = EmbeddingService.generate(text)

    where.not(embedding: nil)
         .nearest_neighbors(
           :embedding,
           query_embedding,
           distance: "cosine"
         )
         .first
  end

  def generate_embedding!
    text = [
      setting,
      description
    ].compact.join(" ")

    update!(
      embedding: EmbeddingService.generate(text)
    )
  end
end
