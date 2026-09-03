class CreditWordUsage
  def self.call(message)
    new(message).call
  end

  def self.recheck(message)
    new(message).recheck
  end

  def initialize(message)
    @message   = message
    @adventure = message.adventure
  end

  # first pass, runs in the request: records what the deterministic matcher can see straight away, as pending.
  # Nothing is counted until the review agrees.
  def call
    return unless @message.role == "user"

    credit(@adventure.target_words.to_a.select { |w| used?(w) })
  end

  # second pass, runs in the background job — asks the model about words the
  # first pass couldn't reach, like する and 来る
  def recheck
    return unless @message.role == "user"

    words = unchecked_words
    return if words.empty?

    credit(ModelWordMatcher.call(@message.body, words))
  rescue StandardError => e
    Rails.logger.error("CreditWordUsage.recheck failed: #{e.message}")
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

  # practice words this message has no usage row for yet, whatever their status
  def unchecked_words
    already = @message.word_usages.pluck(:saved_word_id)
    @adventure.practice_words.reject { |w| already.include?(w.id) }
  end

  # Deterministic first pass. ModelWordMatcher (in #recheck) is the paid
  # second pass for the irregulars this can't reach.
  def used?(word)
    ConjugationMatcher.match?(@message.body, word)
  end
end
