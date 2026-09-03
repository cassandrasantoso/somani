class WordNormalizer
  def self.call(surface)
    new(surface).call
  end

  def initialize(surface)
    @surface = surface
  end

  # Returns the dictionary form as a String, or nil if unparseable / not a word.
  # Transport errors propagate, SavedWordsController#lookup_normalized_entry
  # already rescues at the call site.
  def call
    client = Gemini.new(
      credentials: {
        service: "generative-language-api",
        api_key: ENV.fetch("GEMINI_API_KEY")
      },
      options: {
        model: ENV.fetch("GEMINI_MODEL")
      }
    )

    response = client.generate_content(
      { contents: [{ role: "user", parts: [{ text: prompt }] }] }
    )

    parse(response.dig("candidates", 0, "content", "parts", 0, "text").to_s)
  end

  private

  def prompt
    <<~PROMPT
      Give the dictionary form (辞書形) of the Japanese word "#{@surface}".

      If it is already in dictionary form, return it unchanged.
      If it is not a Japanese word, return null.

      Examples:
        上がり     → 上がる
        食べました → 食べる
        物価       → 物価

      Respond with only JSON, no other text:
      {"dictionary_form": "上がる"}
    PROMPT
  end

  # Same fence-stripping as WordLevelEstimator#parse and ReviewMessageJob#parse.
  def parse(text)
    cleaned = text.gsub(/```(?:json)?/, "").strip
    match   = cleaned[/\{.*\}/m]
    return nil unless match

    JSON.parse(match, symbolize_names: true)[:dictionary_form].to_s.strip.presence
  rescue JSON::ParserError
    Rails.logger.warn("WordNormalizer unparseable for #{@surface.inspect}: #{text.truncate(200)}")
    nil
  end
end
