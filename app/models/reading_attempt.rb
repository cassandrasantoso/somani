class ReadingAttempt < ApplicationRecord
  MODES = %w[reading listening].freeze

  belongs_to :user
  belongs_to :reading_passage

  enum :mode, { reading: "reading", listening: "listening" }, default: :reading

  # Speed only applies to reading: listening is comprehension-only, so wpm
  # is null there and the validation is conditional.
  validates :wpm, numericality: { greater_than: 0 }, if: :reading?
  validates :wpm, absence: true, if: :listening?
  validates :comprehension, numericality: { in: 0..100 }
  validates :duration_ms, numericality: { greater_than: 0 }

  # The next speed to aim for: 10% faster than the current best, with
  # comprehension held at 70%+ — speed without comprehension isn't reading.
  def next_target_wpm
    base = ReadingAttempt.where(user: user, reading_passage: reading_passage, mode: :reading)
                         .where("comprehension >= ?", 70)
    best = [base.maximum(:wpm).to_i, wpm.to_i].max
    (best * 1.1).round
  end
end
