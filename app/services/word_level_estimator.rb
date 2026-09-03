class WordLevelEstimator
  VALID_LEVELS = %w[N5 N4 N3 N2 N1].freeze

  def self.call(surface, reading: nil, meaning: nil)
    new(surface, reading: reading, meaning: meaning).call
  end

  def initialize(surface, reading: nil, meaning: nil)
    @surface = surface
    @reading = reading
    @meaning = meaning
  end

  # Returns { in_scope:, level:, category: } or nil if the response couldn't be parsed at all (see #parse).
  # Transport/API errors (rate limits, network failures) are not rescued here and propagate to the caller,
  # matching how ReviewMessageJob#perform rescues at the call site rather than inside parsing.
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
      {
        contents: [
          {
            role: "user",
            parts: [
              { text: prompt }
            ]
          }
        ]
      }
    )

    text = response.dig("candidates", 0, "content", "parts", 0, "text").to_s
    parse(text)
  end

  private

  def prompt
    <<~PROMPT
      Word: #{@surface}#{" (#{@reading})" if @reading.present?}
      #{"Meaning: #{@meaning}" if @meaning.present?}

      Is this general-purpose Japanese vocabulary of the kind tested
      by the JLPT — or is it a proper noun, brand, place name, culinary term,
      technical term, or recent loanword?

      Do not assign N1 merely because a word is uncommon or absent from
      standard lists. N1 means advanced *general* Japanese. A word simply
      outside JLPT vocabulary — a brand, a dish, a place, a specialist term —
      must be returned as out of scope, not as N1.

      Examples:
        デミグラスソース → out_of_scope, category "loanword"   (not N1)
        大宮             → out_of_scope, category "place name" (not N1)
        回転寿司         → in scope, estimate a level

      If in scope, estimate its JLPT level (N5-N1). No confidence score.

      Respond with only JSON, no other text:
      {"in_scope": true|false, "level": "N3"|null, "category": "loanword"|null}
    PROMPT
  end

  # Same fence-stripping + brace-extraction as ReviewMessageJob#parse,
  # so a markdown-wrapped or chatty response doesn't blow up JSON.parse.
  # Returns nil on anything unparseable rather than raising,
  # the caller decides what "no estimate" means.
  def parse(text)
    cleaned = text.gsub(/```(?:json)?/, "").strip
    match   = cleaned[/\{.*\}/m]
    return nil unless match

    parsed = JSON.parse(match, symbolize_names: true)
    level  = VALID_LEVELS.include?(parsed[:level]) ? parsed[:level] : nil

    {
      # Strict equality on purpose, matching ReviewMessageJob#sanitize:
      # anything but a literal true — missing, null, a stray string means "not in scope."
      # A confused model should shrink what it affects, not risk mislabeling a word N1.
      in_scope: parsed[:in_scope] == true,
      level: level,
      category: parsed[:category].to_s.strip.presence
    }
  rescue JSON::ParserError
    Rails.logger.warn("WordLevelEstimator unparseable for #{@surface.inspect}: #{text.truncate(200)}")
    nil
  end
end
