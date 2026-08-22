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
end
