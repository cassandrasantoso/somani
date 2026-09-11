class ReadingPassage < ApplicationRecord
  belongs_to :upload
  has_many :reading_attempts, dependent: :destroy

  MIN_PASSAGE_CHARS = 250
  MAX_PASSAGE_CHARS = 600
  SENTENCE_END = /(?<=[。！？!?\n])/

  # Deterministic split: passages of ~250-600 characters cut at sentence
  # boundaries, so a drill is the same every time and question generation is
  # the only thing the model does. Text under MIN becomes one passage.
  def self.split_into_passages(text)
    cleaned = text.to_s.gsub(/\s+/, " ").strip
    return [] if cleaned.blank?

    sentences = cleaned.split(SENTENCE_END).map(&:strip).reject(&:blank?)
    passages = []
    current = +""

    sentences.each do |sentence|
      if current.length + sentence.length > MAX_PASSAGE_CHARS && current.length >= MIN_PASSAGE_CHARS
        passages << current.dup
        current = +""
      end
      current << sentence
    end
    passages << current.dup if current.present?

    passages.reject(&:blank?)
  end
end
