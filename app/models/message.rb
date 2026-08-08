class Message < ApplicationRecord
  ROLES = %w[user assistant].freeze

  belongs_to :adventure
  has_one :feedback, dependent: :destroy
  has_one_attached :audio

  validates :role, inclusion: { in: ROLES }
  validates :body, presence: true

  scope :chronological, -> { order(:created_at) }
end
