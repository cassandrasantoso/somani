class Message < ApplicationRecord
  ROLES = %w[user assistant].freeze

  belongs_to :adventure
  has_one :feedback, dependent: :destroy
  has_one_attached :audio
  has_many :word_usages, dependent: :destroy

  validates :role, inclusion: { in: ROLES }
  validates :body, presence: true

  scope :chronological, -> { order(:created_at) }

  after_create_commit lambda {
    broadcast_append_to adventure, target: "messages", partial: "messages/message", locals: { message: self }
  }
end
