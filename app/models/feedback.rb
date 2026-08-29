class Feedback < ApplicationRecord
  belongs_to :message

  KINDS = %w[grammar vocabulary nuance].freeze

  def clean? = corrections.blank?
end
