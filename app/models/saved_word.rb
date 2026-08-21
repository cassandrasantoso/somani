class SavedWord < ApplicationRecord
  belongs_to :user
  belongs_to :jlpt_entry, optional: true

  has_many :uploaded_words, dependent: :destroy
  has_many :uploads, through: :uploaded_words
  has_many :adventures, through: :uploads

  validates :surface, presence: true, uniqueness: { scope: :user_id }

  scope :due, -> { where(next_review_at: ..Time.current) }

  # e.g. current_user.saved_words.pick_most_common_level => "N3"
  def self.pick_most_common_level
    group(:level).count.max_by { |_level, count| count }&.first
  end
end
