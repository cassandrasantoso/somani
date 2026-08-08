class SavedWord < ApplicationRecord
  belongs_to :user
  belongs_to :jlpt_entry, optional: true

  has_many :uploaded_words, dependent: :destroy
  has_many :uploads, through: :uploaded_words

  validates :surface, presence: true, uniqueness: { scope: :user_id }

  scope :due, -> { where(next_review_at: ..Time.current) }
end
