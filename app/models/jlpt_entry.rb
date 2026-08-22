class JlptEntry < ApplicationRecord
  ENTRY_TYPES = %w[word grammar proverb].freeze
  has_many :saved_words, dependent: :nullify

  scope :by_level, ->(level) { where(level: level) if level.present? }
  scope :by_type,  ->(type)  { where(entry_type: type) if type.present? }
  scope :words,    -> { by_type("word") }

  # the following scope is equivalent to:
  # SELECT * FROM jlpt_entries
  # WHERE content ILIKE '%会%' OR reading ILIKE '%会%' OR meaning ILIKE '%会%'
  scope :search, lambda { |q|
    next if q.blank?

    where("content ILIKE :q OR reading ILIKE :q OR meaning ILIKE :q", q: "%#{q}%")
  }
end
