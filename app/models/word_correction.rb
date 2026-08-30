class WordCorrection < ApplicationRecord
  belongs_to :feedback
  belongs_to :saved_word, optional: true
  belongs_to :user

  validates :surface, :kind, :wrote, :better, presence: true
  validates :kind, inclusion: { in: Feedback::KINDS }

  scope :for_word, lambda { |word|
    where(user_id: word.user_id, surface: word.surface)
  }

  scope :newest_first, -> { order(created_at: :desc) }
end
