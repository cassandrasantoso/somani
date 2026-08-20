require "gemini-ai"

class ModelWordMatcher
  GEMINI_MODEL = "gemini-3.5-flash"

  def self.call(body, words)
    new(body, words).call
  end

  def initialize(body, words)
    @body  = body.to_s
    @words = words
  end

  def call
    return [] if @body.blank? || @words.empty?

    parse(raw_response).filter_map do |i|
      @words[i - 1] if i.between?(1, @words.size)
    end
  end

  private

  def raw_response
    response = gemini_client.generate_content(
      { contents: [{ role: "user", parts: [{ text: prompt }] }] }
    )
    response.dig("candidates", 0, "content", "parts", 0, "text").to_s
  end

  def prompt
    listed = @words.each_with_index.map { |w, i| "#{i + 1}. #{w.surface}" }.join("\n")

    <<~PROMPT
      A Japanese learner is practising these words:

      #{listed}

      They wrote:

      #{@body}

      Which of the listed words did they actually use? Count any inflected,
      conjugated or politeness-shifted form — しました counts as する,
      高かった counts as 高い, 行きました counts as 行く. Do not count a word
      merely because it shares a kanji with something in the sentence:
      銀行 does not count as 行く.

      Return only a JSON array of the numbers, for example [1,3].
      Return [] if none were used.
    PROMPT
  end

  # Asked for bare JSON, but models wrap it in prose or a code fence often
  # enough that pulling the first bracketed group out is worth the two lines.
  def parse(text)
    match = text[/\[[^\]]*\]/]
    return [] if match.nil?

    JSON.parse(match).grep(Integer)
  rescue JSON::ParserError
    []
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
