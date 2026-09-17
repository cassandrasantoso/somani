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
    parsed = GeminiClient.generate_json(prompt, symbolize_names: true)
    return nil unless parsed.is_a?(Hash)

    parsed[:dictionary_form].to_s.strip.presence
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
end
