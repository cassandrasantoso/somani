# app/jobs/opening_line_job.rb
require "gemini-ai"

class OpeningLineJob < ApplicationJob
  queue_as :default

  retry_on Faraday::TooManyRequestsError, wait: :polynomially_longer, attempts: 5

  GEMINI_MODEL = "gemini-3.5-flash"

  def perform(adventure)
    opening_text = generate_opening(adventure)

    adventure.messages.create!(role: "assistant", body: opening_text)
  end

  private

  def generate_opening(adventure)
    response = gemini_client.generate_content({
                                                contents: [
                                                  {
                                                    role: "user",
                                                    parts: [{ text: prompt(adventure) }]
                                                  }
                                                ]
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
      Reply only in natural Japanese dialogue. Keep it concise (1-3 sentences).
      Do not break character, do not include English translations, and do not
      add stage directions or narration outside dialogue.
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

  def gemini_client
    Gemini.new(
      credentials: {
        service: "generative-language-api",
        api_key: ENV.fetch("GEMINI_API_KEY")
      },
      options: { model: GEMINI_MODEL }
    )
  end
end
