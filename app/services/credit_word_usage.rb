class CreditWordUsage
  def self.call(message)
    new(message).call
  end

  def initialize(message)
    @message   = message
    @adventure = message.adventure
  end

  def call
    return unless @message.role == "user"

    matched = @adventure.target_words.to_a.select { |w| used?(w) }
    return if matched.empty?

    now = Time.current
    rows = matched.map do |w|
      { adventure_id: @adventure.id, saved_word_id: w.id,
        message_id: @message.id, created_at: now, updated_at: now }
    end

    # the unique index means a word can only be credited once per message
    WordUsage.insert_all(rows, unique_by: %i[message_id saved_word_id])

    @adventure.check_goal!
    broadcast_tracker
  end

  private

  def broadcast_tracker
    words  = @adventure.target_words
    counts = @adventure.usage_counts

    @adventure.broadcast_replace_to(
      @adventure,
      target: "word-tracker",
      partial: "adventures/tracker",
      locals: { adventure: @adventure,
                target_words: words,
                usage_counts: counts }
    )
  end

  # accept any of: the form they saved, its reading, or the dictionary form
  # from jlpt_entries. e.g. catches "saved 出席した, typed 出席する" and vice versa.
  def used?(word)
    body  = @message.body.to_s
    forms = [word.surface, word.reading, word.jlpt_entry&.content].compact_blank.uniq

    forms.any? { |f| body.include?(f) }
  end
end
