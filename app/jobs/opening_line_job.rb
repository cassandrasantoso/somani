# app/jobs/opening_line_job.rb
require "gemini-ai"

class OpeningLineJob < ApplicationJob
  queue_as :default

  GEMINI_MODEL = "gemini-3.5-flash"

  def perform(adventure)
    scene = adventure.scene
    character = scene.character

    opening_text = generate_opening(character, scene)

    adventure.messages.create!(role: "assistant", body: opening_text)
  end

  private

  def generate_opening(character, scene)
    response = gemini_client.generate_content({
                                                contents: [
                                                  {
                                                    role: "user",
                                                    parts: [{ text: prompt(character, scene) }]
                                                  }
                                                ]
                                              })

    response.dig("candidates", 0, "content", "parts", 0, "text").to_s.strip
  end

  def prompt(character, scene)
    <<~PROMPT
      You are role-playing as #{character.name} in a Japanese-language learning adventure.

      Character: #{character.persona}
      Scene: #{scene.setting} — #{scene.description}
      Target level: JLPT #{scene.level}

      Write the character's OPENING line to start this scene — the very first
      thing they say to the learner, setting the scene and inviting a reply.
      Reply only in natural Japanese dialogue. Keep it concise (1-3 sentences).
      Do not break character, do not include English translations, and do not
      add stage directions or narration outside dialogue.
    PROMPT
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
