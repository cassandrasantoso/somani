# Matches a feedback's corrections against the words this message used, writing one row per hit.
# Most corrections won't match any word - that's expected, not a bug.
class IndexWordCorrections
  def self.call(feedback) = new(feedback).call

  def initialize(feedback)
    @feedback  = feedback
    @message   = feedback.message
    @adventure = @message.adventure
  end

  def call
    return if @feedback.corrections.blank?

    words = candidate_words
    return if words.empty?

    rows = build_rows(words)
    return if rows.empty?

    WordCorrection.insert_all(rows)
  end

  private

  # Only words this message was credited for — narrower than target_words,
  # and it already includes the model pass since ReviewMessageJob runs after
  # CreditWordUsage.recheck.
  def candidate_words
    SavedWord.where(id: @message.word_usages.select(:saved_word_id))
             .includes(:jlpt_entry)
             .to_a
  end

  def build_rows(words)
    user = @adventure.user
    now  = Time.current

    @feedback.corrections.flat_map do |c|
      words.filter_map do |word|
        # Match against `wrote`, not `better` — we're indexing what the learner
        # actually said, not the model's corrected version.
        next unless ConjugationMatcher.match?(c["wrote"], word)

        { feedback_id: @feedback.id,
          saved_word_id: word.id,
          user_id: user.id,
          surface: word.surface,
          kind: c["kind"],
          wrote: c["wrote"],
          better: c["better"],
          why: c["why"],
          created_at: now,
          updated_at: now }
      end
    end
  end
end
