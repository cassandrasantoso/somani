class CreditWordUsage
  def self.call(message)
    new(message).call
  end

  def initialize(message)
    @message   = message
    @adventure = message.adventure
  end

  # first pass, runs in the request: records what the deterministic matcher can see straight away, as pending.
  # Nothing is counted until the review agrees — the review also reports the
  # inflected matches this can't reach (see ReviewMessageJob#credit_reported_words).
  def call
    return unless @message.role == "user"

    credit(@adventure.target_words.to_a.select { |w| used?(w) })
  end

  private

  def credit(words)
    return if words.empty?

    now = Time.current
    rows = words.map do |w|
      { adventure_id: @adventure.id, saved_word_id: w.id,
        message_id: @message.id, status: "pending",
        created_at: now, updated_at: now }
    end

    WordUsage.insert_all(rows, unique_by: %i[message_id saved_word_id])

    # No check_goal! or broadcasts here any more: pending rows don't count toward usage_counts,
    # so nothing the learner can see has changed yet.
    # ReviewMessageJob#confirm_pending does that once the review agrees.
  end

  # Deterministic first pass. The review job's model pass is the paid
  # second pass for the irregulars this can't reach.
  def used?(word)
    ConjugationMatcher.match?(@message.body, word)
  end
end
