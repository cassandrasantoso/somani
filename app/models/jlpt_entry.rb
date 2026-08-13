class JlptEntry < ApplicationRecord
  ENTRY_TYPES = %w[word grammar proverb].freeze
  has_many :saved_words, dependent: :nullify

  scope :by_level, ->(level) { where(level: level) if level.present? }
  scope :by_type,  ->(type)  { where(entry_type: type) if type.present? }

  # the following scope is equivalent to:
  # SELECT * FROM jlpt_entries
  # WHERE content ILIKE '%会%' OR reading ILIKE '%会%' OR meaning ILIKE '%会%'
  scope :search, lambda { |q|
    next if q.blank?

    where("content ILIKE :q OR reading ILIKE :q OR meaning ILIKE :q", q: "%#{q}%")
  }
end

class Upload < ApplicationRecord
  MEDIA_TYPES = %w[audio document photo].freeze

  belongs_to :user
  has_many :uploaded_words, dependent: :destroy
  has_many :saved_words, through: :uploaded_words
  has_many :adventures, dependent: :destroy

  has_one_attached :file

  validates :media_type, inclusion: { in: MEDIA_TYPES }
  validates :file, presence: true

  # Returns the seeded JlptEntry records whose content actually appears
  # in this upload's extracted text — used to highlight/suggest matches
  # on the analyzed page.
  def matched_jlpt_entries
    return JlptEntry.none if extracted_text.blank?

    JlptEntry.select { |entry| extracted_text.include?(entry.content) }
  end
end
