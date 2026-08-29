class WordCorrection < ApplicationRecord
  belongs_to :feedback
  belongs_to :saved_word, optional: true
  belongs_to :user

  validates :surface, :kind, :wrote, :better, presence: true
  validates :kind, inclusion: { in: Feedback::KINDS }
end
