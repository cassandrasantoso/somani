# app/services/translate_message.rb
class TranslateMessage
  def self.call(message)
    new(message).call
  end

  def initialize(message)
    @message = message
  end

  def call
    Llm.generate_text(prompt)
  end

  private

  attr_reader :message

  def prompt
    <<~PROMPT
      Translate the following Japanese text into natural, fluent English.
      Return ONLY the translation, with no commentary, quotation marks, or
      explanation.

      Japanese text:
      #{message.body}
    PROMPT
  end
end
