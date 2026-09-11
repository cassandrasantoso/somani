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
  has_many :reading_passages, dependent: :destroy

  has_one_attached :file

  before_validation :detect_media_type

  validates :file, presence: true
  validate  :file_must_be_readable

  enum :extraction_status, { pending: "pending", ready: "ready", failed: "failed" }, default: :pending

  UNSAFE_SINGLE_CHAR = /\A[\p{Hiragana}\p{Katakana}ー]\z/

  def self.media_type_for(content_type)
    type = content_type.to_s.downcase.split(";").first.to_s.strip

    return "photo"    if type.start_with?("image/")
    return "audio"    if type.start_with?("audio/")
    return "document" if DOCUMENT_TYPES.include?(type)

    nil
  end

  # Seeded words that appear in this upload's text. The candidate contents are
  # cached (the full list is ~8k rows), matched in memory, and only the
  # matches go back to the database through the indexed equality lookup —
  # no per-request sequential scan.
  def matched_jlpt_entries
    return JlptEntry.none if extracted_text.blank?

    matched = self.class.entry_contents.select { |content| extracted_text.include?(content) }
    matched = matched.reject { |content| content.length == 1 && content.match?(UNSAFE_SINGLE_CHAR) }

    JlptEntry.words.where(content: matched)
  end

  def self.entry_contents
    Rails.cache.fetch("jlpt/entry_contents", expires_in: 1.hour) do
      JlptEntry.words.where.not(content: [nil, ""]).distinct.pluck(:content)
    end
  end

  def highest_word_level
    saved_words.where.not(level: nil).filter_map { |w| SavedWord::LEVEL_ENUM[w.level.to_s.to_sym] }.min
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

  # Same locals the word picker is rendered with everywhere else
  # (UploadsController#show, SavedWordsController#create), so the async
  # extraction completion can refresh the study material in place.
  def broadcast_word_picker
    broadcast_replace_to(
      self,
      target: "word-picker",
      partial: "uploads/word_picker",
      locals: { upload: self,
                matched_entries: matched_jlpt_entries,
                already_saved_surfaces: user.saved_words.pluck(:surface) }
    )
  end

  def broadcast_summary
    broadcast_replace_to(
      self,
      target: "upload-summary",
      partial: "uploads/summary",
      locals: { upload: self }
    )
  end

  def broadcast_reading_drill
    broadcast_replace_to(
      self,
      target: "reading-drill",
      partial: "reading_drills/drill",
      locals: { upload: self }
    )
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
