require "gemini-ai"

class ReviewMessageJob < ApplicationJob
  queue_as :default

  # Same pattern as GenerateUploadSummaryJob — a rate-limited feedback pass is
  # worth retrying later, not worth failing loudly.
  retry_on Faraday::TooManyRequestsError, wait: :polynomially_longer, attempts: 5
  discard_on ActiveJob::DeserializationError

  # Short acknowledgements have nothing to correct. Grading 「はい」 to say
  # "looks good" teaches the learner that the marker means nothing. But a
  # message that credited a practice word is never a trivial acknowledgement,
  # whatever its length - see the word_usages.none? exception below.
  MIN_LENGTH = 10

  def perform(message)
    return unless message.role == "user"
    return if message.adventure.draft? # no scene yet — see note below
    return if message.feedback.present?
    return if message.body.to_s.strip.length < MIN_LENGTH && message.word_usages.none?

    data = parse(raw_response(message))
    return if data.blank?

    feedback = message.create_feedback!(
      assessment: data["assessment"].to_s.strip.presence,
      level_estimate: data["level_estimate"].to_s.strip.presence,
      coherence: coherence_for(message, data),
      coherence_note: data["coherence_note"].to_s.strip.presence,
      corrections: sanitize(data["corrections"])
    )

    index_corrections(feedback)

    broadcast(message)
  rescue Faraday::TooManyRequestsError
    raise # let retry_on handle it
  rescue StandardError => e
    Rails.logger.warn("ReviewMessageJob #{message.id}: #{e.class}: #{e.message}")
  end

  private

  # Everything off a model is untrusted: cap at 3 even if the prompt is
  # ignored, drop malformed rows, and never let an unknown kind reach a CSS
  # class name.
  def sanitize(raw)
    Array(raw).first(3).filter_map do |c|
      next unless c.is_a?(Hash) && c["wrote"].present? && c["better"].present?

      { "kind" => Feedback::KINDS.include?(c["kind"]) ? c["kind"] : "grammar",
        "wrote" => c["wrote"].to_s,
        "better" => c["better"].to_s,
        "why" => c["why"].to_s,
        # Strict equality on purpose: anything but a literal true hence missing,
        # null, the string "true" means keep the credit.
        # A confused model must never be able to take a word off a learner.
        "on_practice_word" => c["on_practice_word"] == true,
        "practice_word" => c["practice_word"].to_s.strip.presence }
    end
  end

  def raw_response(message)
    response = gemini_client.generate_content(
      { contents: [{ role: "user", parts: [{ text: prompt(message) }] }] }
    )
    response.dig("candidates", 0, "content", "parts", 0, "text").to_s
  end

  def parse(text)
    cleaned = text.gsub(/```(?:json)?/, "").strip
    match   = cleaned[/\{.*\}/m]
    match ? JSON.parse(match) : nil
  rescue JSON::ParserError
    Rails.logger.warn("ReviewMessageJob unparseable: #{text.truncate(200)}")
    nil
  end

  def broadcast(message)
    message.broadcast_replace_to(
      message.adventure,
      target: ActionView::RecordIdentifier.dom_id(message, :feedback),
      partial: "feedbacks/feedback",
      locals: { message: message }
    )
  end

  def gemini_client
    Gemini.new(
      credentials: { service: "generative-language-api",
                     api_key: ENV.fetch("GEMINI_API_KEY") },
      options: { model: ENV.fetch("GEMINI_MODEL") }
    )
  end

  def prompt(message)
    adventure = message.adventure
    scene     = adventure.scene
    character = scene.character

    <<~PROMPT
      A Japanese learner is having a role-play conversation for practice.
      You are reviewing ONE line they wrote. You are not part of the conversation.

      Situation: #{scene.setting} — #{scene.description}
      They are speaking to: #{character.name} — #{character.persona}
      Their target level: JLPT #{scene.level}

      #{previous_turn(message)}
      The learner wrote:
      #{message.body}

      #{target_word_note(adventure)}

      Review the Japanese on three things:
        grammar    — particles, conjugation, sentence structure
        vocabulary — wrong word for the meaning they intended, or a word that
                     does not fit this situation
        nuance     — politeness level and naturalness for the specific person
                     they are speaking to here

      Rules:
      - At most 3 corrections, most important first.
      - Correct at or near their level. Do not rewrite their sentence into
        advanced native prose — a correction they could not have produced
        themselves teaches them nothing.
      - If the line is acceptable, return an empty corrections array. Do not
        invent faults to seem useful. Slightly awkward but valid Japanese is
        acceptable Japanese.
      - Never judge their opinions, their choices, or what they decided to talk
        about. Do judge whether their reply connects to what was said to them.

      Separately from the Japanese itself, judge whether their reply engages
      with what was just said to them:

        responsive — it engages with what was said, including indirectly
        partial    — it engages with only part of what was asked
        off_topic  — it reads as though they misunderstood or ignored it

      Judging this, be careful:
      - Japanese replies are often indirect, and indirect is not off-topic.
        「行きませんか」 answered with 「ちょっと…」 is a complete and correct
        refusal. 「どうですか」 answered with 「そうですね…」 is engaged.
        Implication, hedging and omitted subjects are normal Japanese — never
        treat them as evasion or as a failure to answer.
      - Deliberately changing the subject is a normal conversational move, not
        a mistake. Only flag a reply when it reads as a misunderstanding of
        what was said, not as a choice about where to take the conversation.
      - If there was no previous line to respond to, return null.

      Return only JSON, no other text:
      {"assessment": "one short warm, specific sentence about this line",
       "level_estimate": "N5, N4, N3, N2 or N1",
       "coherence": "responsive, partial, off_topic, or null",
       "coherence_note": "one short sentence naming what was asked and what
                          they answered — only when not responsive, otherwise null",
       "corrections": [
         {"kind": "grammar, vocabulary or nuance",
          "wrote": "the exact fragment they wrote",
          "better": "the corrected fragment",
          "why": "one short sentence, in English",
          "on_practice_word": true or false,
          "practice_word": "the exact practiced word, or null"}
       ]}
    PROMPT
  end

  # A reply is only correct relative to what was asked — particles, ellipsis
  # and register all depend on the previous turn.
  def previous_turn(message)
    prior = message.adventure.messages
                   .where(role: "assistant")
                   .where(created_at: ...message.created_at)
                   .order(:created_at)
                   .last
    return "" if prior.blank?

    "They were replying to:\n#{prior.body}\n"
  end

  # If they reached for a practice word and fumbled it, fix the usage — don't
  # suggest a cleaner sentence that drops the word. Producing it is the point.
  def target_word_note(adventure)
    words = adventure.target_words.map(&:surface)
    return "" if words.empty?

    <<~TEXT
      They are deliberately practising these words: #{words.join('、')}.
      If one is used imperfectly, correct how it is used but keep the word.

      For each correction, set on_practice_word to true when your correction
      changes one of those words or the grammar attached to it — its
      conjugation or form, a する or auxiliary wrongly added to it or missing
      from it, the particle immediately governing it, or a different word
      substituted for it.

      For each correction where on_practice_word is true, also set
      practice_word to the exact surface of the practiced word it's about,
      copied exactly from the list above. Set it to null otherwise.

      Set it to false only when the practice word and the grammar attached to
      it are identical in "wrote" and "better" — the word merely appears
      inside a fragment whose real problem is elsewhere.

      Examples, if 方法 and 食べる were being practised:
        "仕事の方法するのが" → "仕事の方法が"        on_practice_word: true
        "寿司を食べるました" → "寿司を食べました"      on_practice_word: true
        "方法を教えてくれ"   → "方法を教えてください"  on_practice_word: false
    TEXT
  end

  # Isolated so a bug in the indexer can't be mistaken for a feedback-
  # generation failure in the logs, and can't stop feedback from reaching
  # the learner either.
  def index_corrections(feedback)
    IndexWordCorrections.call(feedback)
  rescue StandardError => e
    Rails.logger.warn("IndexWordCorrections feedback=#{feedback.id}: #{e.class}: #{e.message}")
  end

  # Whitelisted, and only meaningful when there was something to respond to.
  # previous_turn returns "" for the first user line, and coherence against
  # nothing is not a judgement worth storing.
  def coherence_for(message, data)
    return nil if previous_turn(message).blank?

    value = data["coherence"].to_s.strip
    Feedback::COHERENCE.include?(value) ? value : nil
  end
end
