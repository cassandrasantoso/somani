class Scene < ApplicationRecord
  belongs_to :character
  has_neighbors :embedding
  has_many :adventures, dependent: :restrict_with_error

  after_create_commit :enqueue_embedding

  DEFAULT_LEVEL = "N2".freeze

  # Picks the scene whose description sits closest to the words being
  # practised, by cosine distance over the embeddings. Scenes without an
  # embedding are invisible to this search, so if none are embedded it
  # returns nil - and the caller assigns the result straight to a required
  # belongs_to.
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
  rescue Faraday::TooManyRequestsError => e
    Rails.logger.error("Scene.nearest_to_words: rate limited (#{e.message})")
    where.not(embedding: nil).first
  end

  def generate_embedding!
    text = [setting, description].compact_blank.join(" ")
    raise ArgumentError, "Scene ##{id} has no text to embed" if text.blank?

    vector = EmbeddingService.generate(text)
    raise "EmbeddingService returned no vector for Scene ##{id}" if vector.blank?

    update!(embedding: vector)
  end

  private

  def enqueue_embedding
    GenerateSceneEmbeddingJob.perform_later(self)
  end
end
