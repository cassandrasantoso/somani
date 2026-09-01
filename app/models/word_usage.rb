class WordUsage < ApplicationRecord
  STATUSES = %w[credited revoked].freeze

  belongs_to :adventure
  belongs_to :saved_word
  belongs_to :message

  validates :status, inclusion: { in: STATUSES }

  scope :credited, -> { where(status: "credited") }
  scope :revoked,  -> { where(status: "revoked") }
end
