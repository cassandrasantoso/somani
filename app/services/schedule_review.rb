# The end of an adventure is when the app knows most about these words,
# and the only moment it can schedule review without asking the learner to.
#
# A word whose goal was met with no revocations is a successful production:
# it gets a "good" grade. Anything else — goal unmet, or credited then
# revoked — comes back within minutes as an "again", so the next session
# starts with the words that didn't hold up. The SRS engine owns the actual
# intervals; this service only decides which grade the evidence supports.
class ScheduleReview
  def self.call(adventure) = new(adventure).call

  def initialize(adventure)
    @adventure = adventure
  end

  def call
    clean, shaky = buckets

    clean.each { |word| SrsSchedule.call(word, :good) }
    shaky.each { |word| SrsSchedule.call(word, :again) }
  end

  private

  def buckets
    counts  = @adventure.usage_counts
    targets = @adventure.goal_targets
    revoked = @adventure.revoked_counts

    @adventure.target_words.to_a.partition do |w|
      met = counts.fetch(w.id, 0) >= targets.fetch(w.id, WordGoal::DEFAULT_TARGET)
      met && revoked.fetch(w.id, 0).zero?
    end
  end
end
