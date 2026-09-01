# Matches a feedback's corrections against the words this message used, writing one row per hit.
# Most corrections won't match any word i.e. that's expected, not a bug.
# Also takes back credit when the model says the practice word itself was what went wrong.
# Credit is optimistic on send, this is the pass that knows better.
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

    hits = match_hits(words)
    return if hits.empty?

    WordCorrection.insert_all(hits.map { |c, word| row_for(c, word) })
    revoke_credit(hits)
  end

  private

  # One instant for the whole pass, so the indexed corrections and the revocation they caused share a timestamp.
  def now
    @now ||= Time.current
  end

  # Every word this message was credited for, INCLUDING already-revoked ones.
  # A revoked usage still means the learner reached for the word,
  # and that's what makes it worth indexing a correction against.
  def candidate_words
    SavedWord.where(id: @message.word_usages.select(:saved_word_id))
             .includes(:jlpt_entry)
             .to_a
  end

  # [[correction, word], ...] for every pair that matched.
  def match_hits(words)
    @feedback.corrections.flat_map do |c|
      # Match against `wrote`, not `better` — we're indexing what the learner
      # actually said, not the model's corrected version.
      words.filter_map { |w| [c, w] if ConjugationMatcher.match?(c["wrote"], w) }
    end
  end

  def row_for(correction, word)
    { feedback_id: @feedback.id,
      saved_word_id: word.id,
      user_id: @adventure.user.id,
      surface: word.surface,
      kind: correction["kind"],
      wrote: correction["wrote"],
      better: correction["better"],
      why: correction["why"],
      created_at: now,
      updated_at: now }
  end

  # Scoped to this message: the learner may have used the word correctly
  # in an earlier turn, and that credit stands.
  def revoke_credit(hits)
    ids = hits.filter_map { |c, word| word.id if c["on_practice_word"] }.uniq
    return if ids.empty?

    changed = @message.word_usages.credited
                      .where(saved_word_id: ids)
                      .update_all(status: "revoked", updated_at: now)
    return if changed.zero?

    # Unlike crediting, this can move the verdict backwards, so the two-way
    # re-evaluation rather than check_goal!.
    @adventure.re_evaluate_goal!
    @adventure.broadcast_tracker
    @adventure.broadcast_goal_banner
  end
end
