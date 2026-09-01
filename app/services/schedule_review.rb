# The end of an adventure is when the app knows most about these words,
# and the only moment it can schedule review without asking the learner to.
#
# Words that were credited then revoked come back sooner than words that held up.
# That difference is the whole reason near misses are tracked.
#
# The intervals are a starting heuristic, not a researched schedule, so we tune them.
# The defensible part is the ordering, not the numbers.
class ScheduleReview
  CLEAN = 3.days
  SHAKY = 1.day

  def self.call(adventure) = new(adventure).call

  def initialize(adventure)
    @adventure = adventure
  end

  def call
    clean, shaky = buckets
    return if clean.empty? && shaky.empty?

    now = Time.current

    # They practised all of them just now, whatever the outcome.
    SavedWord.where(id: clean + shaky)
             .update_all(last_reviewed_at: now, updated_at: now)

    schedule(shaky, now + SHAKY, now)
    schedule(clean, now + CLEAN, now)
  end

  private

  # Only ever moves a review earlier.
  # A word already due tomorrow from another adventure must not be pushed out to three days because this run went well.
  def schedule(ids, at, now)
    return if ids.empty?

    SavedWord.where(id: ids)
             .where("next_review_at IS NULL OR next_review_at > ?", at)
             .update_all(next_review_at: at, updated_at: now)
  end

  def buckets
    counts  = @adventure.usage_counts
    targets = @adventure.goal_targets
    revoked = @adventure.revoked_counts

    @adventure.target_words.to_a.partition do |w|
      met = counts.fetch(w.id, 0) >= targets.fetch(w.id, WordGoal::DEFAULT_TARGET)
      met && revoked.fetch(w.id, 0).zero?
    end.map { |group| group.map(&:id) }
  end
end
