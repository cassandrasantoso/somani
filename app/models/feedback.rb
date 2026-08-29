class Feedback < ApplicationRecord
  belongs_to :message
  has_many :word_corrections, dependent: :destroy

  KINDS = %w[grammar vocabulary nuance].freeze

  def clean? = corrections.blank?
end
