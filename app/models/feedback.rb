class Feedback < ApplicationRecord
  belongs_to :message
  has_many :word_corrections, dependent: :destroy

  KINDS = %w[grammar vocabulary nuance].freeze

  # Whole-message judgement, deliberately not one of KINDS.
  COHERENCE = %w[responsive partial off_topic].freeze

  validates :coherence, inclusion: { in: COHERENCE }, allow_nil: true

  def clean? = corrections.blank?

  # A reply can be grammatically spotless and still not answer the question.
  def disconnected? = coherence.in?(%w[partial off_topic])
end
