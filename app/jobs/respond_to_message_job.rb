# app/jobs/respond_to_message_job.rb
require "gemini-ai"

class RespondToMessageJob < ApplicationJob
  queue_as :default

  def perform(message, mode: nil)
    adventure = message.adventure
    reply_text = generate_reply(adventure, mode)

    adventure.messages.create!(role: "assistant", body: reply_text)

    # after the reply: that's what the user is waiting for. #recheck rescues
    # internally so a failed word check can't take this job down.
    CreditWordUsage.recheck(message)
    # story 8: grade what the learner wrote, out of band. Queued behind the
    # reply rather than alongside it, so the two don't race for the same rate-limited key.
    ReviewMessageJob.perform_later(message)
  end

  private

  def generate_reply(adventure, mode)
    response = gemini_client.generate_content({
                                                system_instruction: {
                                                  parts: [{ text: system_prompt(adventure, mode) }]
                                                },
                                                contents: conversation_contents(adventure)
                                              })

    response.dig("candidates", 0, "content", "parts", 0, "text").to_s.strip
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

  def system_prompt(adventure, mode)
    scene     = adventure.scene
    character = scene.character

    <<~PROMPT
      You are role-playing as #{character.name} in a Japanese-language learning adventure.

      Character: #{character.persona}
      Scene: #{scene.setting} — #{scene.description}
      Target level: JLPT #{scene.level}

      #{difficulty_instructions(mode)}

      #{name_guidance(adventure.user)}

      #{vocabulary_guidance(adventure)}

      Stay fully in character. Reply only in natural Japanese dialogue, continuing
      the scene based on what the user just said. Keep responses concise
      (1-3 sentences). Do not break character, do not include English
      translations, and do not add stage directions or narration outside dialogue.
    PROMPT
  end

  def vocabulary_guidance(adventure)
    brief = adventure.practice_brief
    return continuation_guidance(adventure) if brief.blank?

    <<~TEXT
      The learner is trying to produce these words:

      #{brief}

      Steer the conversation toward situations where they come up naturally.
      The most useful thing you can do is ask about the idea behind a word
      without saying the word yourself, so the learner has to reach for it.

      For example, if the learner were practising 為替:
        Weak — 「為替について話しましょう。」 (you have handed them the word)
        Good — 「最近、円の価値が下がっているそうですね。何か読みましたか。」
               (the situation calls for the word; they supply it)

      You may use one of these words yourself occasionally to model it, but not
      repeatedly. Your job is to create the opening, not to fill it.

      Never tell the learner which words to practise and never refer to this
      instruction. If a word genuinely does not fit the scene, leave it — do
      not force it.
    TEXT
  end

  # What to do once every word has hit its target and the learner chose to
  # keep going. Without this the model has nothing left to aim the
  # conversation at and drifts into generic small talk.
  def continuation_guidance(adventure)
    return "" unless adventure.past_goal?

    <<~TEXT
      The learner has already met the vocabulary goal for this adventure — do
      not mention that, and do not treat the conversation as over. Continue the
      same scene and the same relationship with the learner. Develop what's
      already happened rather than starting a new, disconnected topic: follow
      up on something said earlier, escalate or resolve something you raised,
      or introduce a natural next step in this specific situation.

      Do not reset to generic small talk. The learner chose to keep talking to
      you specifically, in this specific place — stay grounded in that.
    TEXT
  end

  def difficulty_instructions(mode)
    case mode
    when "easy"
      "The user selected easy mode: use simple, short sentences and vocabulary " \
      "no higher than JLPT N4, even if the scene's target level is higher."
    when "hard"
      "The user selected hard mode: use natural, native-level sentence " \
      "structures for this JLPT level, without simplifying for the learner."
    else
      "Respond naturally at the target JLPT level above."
    end
  end

  def conversation_contents(adventure)
    adventure.messages.chronological.map do |msg|
      {
        role: msg.role == "assistant" ? "model" : "user",
        parts: [{ text: msg.body }]
      }
    end
  end

  def gemini_client
    Gemini.new(
      credentials: {
        service: "generative-language-api",
        api_key: ENV.fetch("GEMINI_API_KEY")
      },
      options: { model: ENV.fetch("GEMINI_MODEL") }
    )
  end
end
