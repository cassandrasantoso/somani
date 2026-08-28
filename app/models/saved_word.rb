class SavedWord < ApplicationRecord
  belongs_to :user
  belongs_to :jlpt_entry, optional: true

  has_many :uploaded_words, dependent: :destroy
  has_many :uploads, through: :uploaded_words
  has_many :adventures, through: :uploads

  validates :surface, presence: true, uniqueness: { scope: :user_id }

  scope :due, -> { where(next_review_at: ..Time.current) }

  LEVEL_ENUM = { N1: 1, N2: 2, N3: 3, N4: 4, N5: 5 }.freeze
end
