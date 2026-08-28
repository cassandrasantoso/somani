class Upload < ApplicationRecord
  MEDIA_TYPES = %w[audio document photo].freeze

  belongs_to :user
  has_many :uploaded_words, dependent: :destroy
  has_many :saved_words, through: :uploaded_words
  has_many :adventures, dependent: :destroy

  has_one_attached :file

  validates :media_type, inclusion: { in: MEDIA_TYPES }
  validates :file, presence: true

  # Seeded words that appear in this upload's text, found in one query
  def matched_jlpt_entries
    return JlptEntry.none if extracted_text.blank?

    JlptEntry.words
             .where.not(content: [nil, ""])
             .where("? LIKE '%' || content || '%'", extracted_text)
  end

  def highest_word_level
    saved_words.map { |word| SavedWord::LEVEL_ENUM[word.level.to_sym] }.min
  end

  # The scene-less adventure created at upload time (see UploadsController#create)
  # that word targets accumulate on before the adventure actually starts.
  def draft_adventure
    adventures.find_by(scene_id: nil)
  end

  # { saved_word_id => target } for the draft adventure, or {} before one exists.
  def word_targets
    draft_adventure&.goal_targets || {}
  end
end
