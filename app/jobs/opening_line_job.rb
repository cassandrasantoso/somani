# app/jobs/opening_line_job.rb
class OpeningLineJob < ApplicationJob
  queue_as :default

  retry_on Faraday::TooManyRequestsError, wait: :polynomially_longer, attempts: 5
  discard_on ActiveJob::DeserializationError

  def perform(adventure)
    body, furigana = generate_opening(adventure)

    message = adventure.messages.create!(role: "assistant", body: body, furigana: furigana)
    GenerateAudioJob.perform_later(message)
  end

  private

  # Returns [body, furigana]; furigana is nil when the segmented response was
  # unusable and the opening fell back to plain text (see RespondToMessageJob).
  def generate_opening(adventure)
    data = GeminiClient.generate_json(prompt(adventure))
    segments = valid_segments(data)

    return [GeminiClient.generate_text(prompt(adventure)), nil] if segments.nil?

    [segments.map { |s| s["base"] }.join, segments]
  end

  def valid_segments(data)
    return nil unless data.is_a?(Hash) && data["segments"].is_a?(Array)

    segments = data["segments"].filter_map do |segment|
      next unless segment.is_a?(Hash) && segment["base"].is_a?(String) && segment["base"].present?

      { "base" => segment["base"], "reading" => segment["reading"].to_s.presence }
    end

    segments.empty? ? nil : segments
  end

  def name_guidance(user)
    name = user.username.presence

    if name.blank?
      return "You do not know the learner's name. Do not use one, and never " \
             "use a placeholder such as ○○さん, 〇〇さん or [name]."
    end

    <<~TEXT
      The learner's name is #{name}. Greet them by name, with the honorific
      your character would naturally use — さん in most situations, 様 if your
      character is serving them professionally. If the name is not Japanese,
      write it in katakana.

      After the greeting, use their name only occasionally. Japanese speakers
      address the person in front of them far less often than English speakers
      do; repeating it every turn sounds unnatural.

      Never use a placeholder such as ○○さん, 〇〇さん or [name].
    TEXT
  end

  def prompt(adventure)
    scene     = adventure.scene
    character = scene.character

    <<~PROMPT
      You are role-playing as #{character.name} in a Japanese-language learning adventure.

      Character: #{character.persona}
      Scene: #{scene.setting} — #{scene.description}
      Target level: JLPT #{scene.level}

      #{name_guidance(adventure.user)}

      #{opening_topic_guidance(adventure)}

      Write the character's OPENING line to start this scene — the very first
      thing they say to the learner, setting the scene and inviting a reply.
      Stay fully in character. Keep it concise (1-2 sentences MAX).
      Do not break character, do not include English translations, and do not
      add stage directions or narration outside dialogue.

      Return the line as JSON in exactly this shape:
      {"segments": [{"base": "今日", "reading": "きょう"}, {"base": "は"}]}

      Segment rules:
      - Concatenated in order, the base values must form your complete line
        exactly, character for character.
      - A segment with kanji in it carries that chunk's kana reading.
        Runs of plain kana, punctuation and numbers have no reading (null).
      - Keep segments short: never merge two words into one segment.
      - Readings are hiragana, or katakana when the base itself is katakana.
    PROMPT
  end

  def opening_topic_guidance(adventure)
    brief = adventure.practice_brief(limit: 8)
    return "" if brief.blank?

    <<~TEXT
      Over this conversation the learner is going to practise these words:

      #{brief}

      Your opening line sets what this conversation is about, so choose a
      starting point that makes as many of them as possible natural to discuss
      — a situation, a piece of news, a problem, a decision they have to make.

      Do not use the words yourself and do not mention that they are being
      practised. Open the door; let them walk through it.
    TEXT
  end
end
