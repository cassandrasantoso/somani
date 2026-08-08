class Adventure < ApplicationRecord
  STATUSES = %w[active completed].freeze

  belongs_to :scene
  belongs_to :upload
  has_many :messages, dependent: :destroy

  delegate :user, to: :upload # so policies can say record.user
  has_one :character, through: :scene

  validates :status, inclusion: { in: STATUSES }
end
