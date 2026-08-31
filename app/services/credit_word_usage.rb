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

  # first pass, runs in the request so the tracker is right when the page
  # credits anything the generated bases can match
  def call
    return unless @message.role == "user"

    credit(@adventure.target_words.to_a.select { |w| used?(w) })
  end

  # second pass, runs in the background job — asks the model about words the
  # first pass couldn't reach, like する and 来る
  def recheck
    return unless @message.role == "user"

    pending = pending_words
    return if pending.empty?

    credit(ModelWordMatcher.call(@message.body, pending))
  rescue StandardError => e
    Rails.logger.error("CreditWordUsage.recheck failed: #{e.message}")
  end

  private

  def credit(words)
    return if words.empty?

    now = Time.current
    rows = words.map do |w|
      { adventure_id: @adventure.id, saved_word_id: w.id,
        message_id: @message.id, created_at: now, updated_at: now }
    end

    WordUsage.insert_all(rows, unique_by: %i[message_id saved_word_id])

    @adventure.check_goal!
    broadcast_tracker
    broadcast_goal_banner
  end

  def broadcast_goal_banner
    @adventure.broadcast_replace_to(
      @adventure,
      target: "goal-banner",
      partial: "adventures/goal_banner",
      locals: { adventure: @adventure }
    )
  end

  # words this message hasn't already credited, and that still need credit
  def pending_words
    already = @message.word_usages.pluck(:saved_word_id)
    @adventure.practice_words.reject { |w| already.include?(w.id) }
  end

  def broadcast_tracker
    words   = @adventure.target_words
    counts  = @adventure.usage_counts
    targets = @adventure.goal_targets

    @adventure.broadcast_replace_to(
      @adventure,
      target: "word-tracker",
      partial: "adventures/tracker",
      locals: { adventure: @adventure,
                target_words: words,
                usage_counts: counts,
                goal_targets: targets }
    )
  end

  # Deterministic first pass. ModelWordMatcher (in #recheck) is the paid
  # second pass for the irregulars this can't reach.
  def used?(word)
    ConjugationMatcher.match?(@message.body, word)
  end
end
