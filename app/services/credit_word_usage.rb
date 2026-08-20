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

    # the unique index means a word can only be credited once per message
    WordUsage.insert_all(rows, unique_by: %i[message_id saved_word_id])

    @adventure.check_goal!
    broadcast_tracker
  end

  # skip words this message already credited, and words that already hit the goal,
  # anything already counted for this message, or already finished, is left out of the prompt
  def pending_words
    already = @message.word_usages.pluck(:saved_word_id)
    counts  = @adventure.usage_counts

    @adventure.target_words.to_a.reject do |w|
      already.include?(w.id) || counts.fetch(w.id, 0) >= @adventure.goal_per_word
    end
  end

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

  # Three spellings (saved form, reading, dictionary form), each expanded
  # into conjugation bases —> so 行きました credits 行く.
  def used?(word)
    body  = @message.body.to_s
    forms = [word.surface, word.reading, word.jlpt_entry&.content].compact_blank.uniq

    forms.flat_map { |f| bases(f) }.uniq.any? { |b| body.include?(b) }
  end

  # Bare する and 来る are exact-match only. Any string short enough to
  # identify them collides with everything else — see the note below.
  IRREGULAR = %w[する くる 来る].freeze

  # Ichidan: the stem plus whatever can follow it.
  # 食べる → 食べ, 食べま(す), 食べた, 食べれ(ば), 食べら(れる)…
  ICHIDAN_BASES = %w[る ま た て な れ ら さ よ].freeze

  # Godan: the final kana shifts within its row. い/っ/ん cover the sound
  # changes in the past and te-forms (書いた, 行った, 飲んだ).
  GODAN_BASES = {
    "う" => %w[わ い う え お っ],
    "く" => %w[か き く け こ い っ],
    "ぐ" => %w[が ぎ ぐ げ ご い],
    "す" => %w[さ し す せ そ],
    "つ" => %w[た ち つ て と っ],
    "ぬ" => %w[な に ぬ ね の ん],
    "ぶ" => %w[ば び ぶ べ ぼ ん],
    "む" => %w[ま み む め も ん],
    "る" => %w[ら り る れ ろ っ]
  }.freeze

  # 高い → 高い, 高く(て), 高かっ(た), 高けれ(ば)
  I_ADJ_BASES = %w[い く かっ けれ].freeze

  # Compound する-verbs: 出席する → 出席し, 出席す, 出席さ, 出席せ
  SURU_BASES = %w[する し す さ せ].freeze

  # The 2+ character strings any inflected form of `form` must start with.
  # Rules are applied additively, not exclusively — a form that isn't a real
  # word just never matches, so guessing wrong costs a miss, not a false credit.
  def bases(form)
    return [form] if IRREGULAR.include?(form)

    out = [form]

    if form.end_with?("する")
      root = form.delete_suffix("する")
      out += SURU_BASES.map { |b| root + b } if root.present?
    end

    if form.end_with?("る")
      root = form.delete_suffix("る")
      out << root
      out += ICHIDAN_BASES.map { |b| root + b }
    end

    if (row = GODAN_BASES[form[-1]])
      root = form[0..-2]
      out += row.map { |k| root + k }
    end

    if form.end_with?("い")
      root = form.delete_suffix("い")
      out += I_ADJ_BASES.map { |b| root + b }
    end

    # the word itself always counts, whatever its length; only generated
    # bases need the 2-character floor
    out.uniq.select { |b| b == form || b.length >= 2 }
  end
end
