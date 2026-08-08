class JlptEntry < ApplicationRecord
  ENTRY_TYPES = %w[word grammar proverb].freeze
  has_many :saved_words, dependent: :nullify

  scope :by_level, ->(level) { where(level: level) if level.present? }
  scope :by_type,  ->(type)  { where(entry_type: type) if type.present? }
end
