class Upload < ApplicationRecord
  # to warn upon mutation of the object it points to
  MEDIA_TYPES = %w[audio document photo].freeze

  belongs_to :user
  has_many :uploaded_words, dependent: :destroy
  has_many :saved_words, through: :uploaded_words
  has_many :adventures, dependent: :destroy

  has_one_attached :file

  validates :media_type, inclusion: { in: MEDIA_TYPES }
  validates :file, presence: true
end
