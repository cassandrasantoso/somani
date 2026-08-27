class Scene < ApplicationRecord
  belongs_to :character
  has_many :adventures, dependent: :restrict_with_error

  DEFAULT_LEVEL = "N2".freeze

  # Orders scenes so ones matching the relevant JLPT level come first.
  # Prefers the level of words saved from this specific upload; falls back
  # to the user's overall saved_words history, then to N2 (the app's target level).
  def self.order_by_relevance_to(upload)
    level = upload.highest_word_level ||
            upload.user.saved_words.pick_most_common_level ||
            DEFAULT_LEVEL

    Scene.where(level: SavedWord::LEVEL_ENUM.key(level))
  end
end
