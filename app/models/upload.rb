class Upload < ApplicationRecord
  MEDIA_TYPES = %w[audio document photo].freeze

  DOCUMENT_TYPES = %w[
    application/pdf
    text/plain
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
  ].freeze

  belongs_to :user
  has_many :uploaded_words, dependent: :destroy
  has_many :saved_words, through: :uploaded_words
  has_many :adventures, dependent: :destroy

  has_one_attached :file

  before_validation :detect_media_type

  validates :file, presence: true
  validate  :file_must_be_readable

  UNSAFE_SINGLE_CHAR = /\A[\p{Hiragana}\p{Katakana}ー]\z/

  def self.media_type_for(content_type)
    type = content_type.to_s.downcase.split(";").first.to_s.strip

    return "photo"    if type.start_with?("image/")
    return "audio"    if type.start_with?("audio/")
    return "document" if DOCUMENT_TYPES.include?(type)

    nil
  end

  # Seeded words that appear in this upload's text, found in one query
  def matched_jlpt_entries
    return JlptEntry.none if extracted_text.blank?

    candidates = JlptEntry.words
                          .where.not(content: [nil, ""])
                          .where("? LIKE '%' || content || '%'", extracted_text)

    candidates.reject { |entry| entry.content.length == 1 && entry.content.match?(UNSAFE_SINGLE_CHAR) }
  end

  def highest_word_level
    saved_words.where(level_source: "jlpt").filter_map { |w| SavedWord::LEVEL_ENUM[w.level.to_s.to_sym] }.min
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

  private

  def detect_media_type
    return unless file.attached?

    self.media_type = self.class.media_type_for(file.content_type)
  end

  def file_must_be_readable
    return if file.blank?
    return if media_type.in?(MEDIA_TYPES)

    errors.add(:file, "needs to be an image, a PDF, a text file, a Word " \
                      "document, or an audio recording")
  end
end
