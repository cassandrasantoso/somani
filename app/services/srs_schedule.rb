# SM-2 style scheduler, three grades: again / good / easy.
#
# The interval ladder for good is 1 day, 3 days, then prior interval * ease;
# easy starts higher and grows faster; again resets repetitions and brings
# the word back within minutes. Ease only moves on again (-0.2) and easy
# (+0.15), floored at 1.3, so a bad streak can't drive the multiplier to zero.
class SrsSchedule
  MIN_EASE = 1.3
  MAX_EASE = 4.0
  EASY_BONUS = 1.3
  LAPSING_DELAY = 10.minutes

  def self.call(saved_word, grade)
    new(saved_word, grade).call
  end

  def initialize(saved_word, grade)
    @word = saved_word
    @grade = grade.to_s
  end

  def call
    @grade == "again" ? forget : recall(easy: @grade == "easy")

    @word.last_reviewed_at = Time.current
    @word.save!
    @word
  end

  private

  def forget
    @word.review_repetitions = 0
    @word.review_interval_days = 0
    @word.review_ease = [@word.review_ease - 0.2, MIN_EASE].max
    @word.next_review_at = Time.current + LAPSING_DELAY
  end

  def recall(easy:)
    repetitions = @word.review_repetitions + 1
    ease = @word.review_ease

    interval = case repetitions
               when 1 then easy ? 2 : 1
               when 2 then easy ? 6 : 3
               else
                 prior = @word.review_interval_days || 3
                 (prior * (easy ? ease * EASY_BONUS : ease)).round
               end

    @word.review_repetitions = repetitions
    @word.review_interval_days = interval
    @word.review_ease = [ease + (easy ? 0.15 : 0), MAX_EASE].min
    @word.next_review_at = Time.current + interval.days
  end
end
