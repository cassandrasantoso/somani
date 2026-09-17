class ModelWordMatcher
  def self.call(body, words)
    new(body, words).call
  end

  def initialize(body, words)
    @body  = body
    @words = words
  end

  def call
    return [] if @body.blank? || @words.empty?

    data = GeminiClient.generate_json(prompt)
    return [] unless data.is_a?(Array)

    data.grep(Integer).filter_map { |i| @words[i - 1] if i.between?(1, @words.size) }
  end

  private

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
end
