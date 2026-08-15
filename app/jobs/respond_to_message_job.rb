# app/jobs/respond_to_message_job.rb
require "gemini-ai"

class RespondToMessageJob < ApplicationJob
  queue_as :default

  GEMINI_MODEL = "gemini-3.5-flash"

  def perform(message, mode: nil)
    adventure = message.adventure
    reply_text = generate_reply(adventure, mode)

    adventure.messages.create!(role: "assistant", body: reply_text)
  end

  private

  def generate_reply(adventure, mode)
    scene = adventure.scene
    character = scene.character

    response = gemini_client.generate_content({
                                                system_instruction: {
                                                  parts: [{ text: system_prompt(character, scene, mode) }]
                                                },
                                                contents: conversation_contents(adventure)
                                              })

    response.dig("candidates", 0, "content", "parts", 0, "text").to_s.strip
  end

  def system_prompt(character, scene, mode)
    <<~PROMPT
      You are role-playing as #{character.name} in a Japanese-language learning adventure.

      Character: #{character.persona}
      Scene: #{scene.setting} — #{scene.description}
      Target level: JLPT #{scene.level}

      #{difficulty_instructions(mode)}

      Stay fully in character. Reply only in natural Japanese dialogue, continuing
      the scene based on what the user just said. Keep responses concise
      (1-3 sentences). Do not break character, do not include English
      translations, and do not add stage directions or narration outside dialogue.
    PROMPT
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
      options: { model: GEMINI_MODEL }
    )
  end
end
