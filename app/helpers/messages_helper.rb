module MessagesHelper
  # Renders a message body with kanji readings attached. Falls back to the raw
  # body for messages created before furigana, or when the model's segmented
  # response was unusable and the reply was stored as plain text.
  def render_furigana(message)
    segments = message.furigana
    return ERB::Util.html_escape(message.body) if segments.blank?

    safe_join(segments.map do |segment|
      base = ERB::Util.html_escape(segment["base"])
      reading = segment["reading"].to_s
      next base if reading.blank?

      "<ruby>#{base}<rt>#{ERB::Util.html_escape(reading)}</rt></ruby>".html_safe
    end)
  end
end
