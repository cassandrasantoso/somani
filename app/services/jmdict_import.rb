require "json"

# Imports JMdict's common words as level-less entries (level_source
# "jmdict"). This is the coverage answer for words the JLPT lists never
# included: they become tappable in uploads immediately, and jisho
# verification assigns levels over time through the existing grind.
# Existing contents are never duplicated or overwritten.
class JmdictImport
  BATCH_SIZE = 1000

  def self.call(path)
    new(path).call
  end

  def initialize(path)
    @path = Pathname.new(path)
  end

  def call
    words = parse_words.select { |word| common?(word) }
    existing = JlptEntry.words.distinct.pluck(:content).to_set
    imported = 0

    words.each do |word|
      content = common_form(word, "kanji") || common_form(word, "kana")
      next if content.blank? || existing.include?(content)

      existing << content
      rows << row_for(word, content)
      flush_rows if rows.size >= BATCH_SIZE
      imported += 1
    end
    flush_rows

    Rails.cache.delete("jlpt/entry_contents")
    { considered: words.size, imported: imported, total: JlptEntry.words.count }
  end

  private

  def rows
    @rows ||= []
  end

  def flush_rows
    return if rows.empty?

    JlptEntry.insert_all(rows)
    rows.clear
  end

  def row_for(word, content)
    now = Time.current

    { content: content,
      reading: common_form(word, "kana") || Array(word["kana"]).first.then do |form|
        form && form["text"]
      end.to_s.presence || content,
      meaning: first_gloss(word),
      entry_type: "word",
      level: nil,
      level_source: "jmdict",
      created_at: now,
      updated_at: now }
  end

  # JMdict flags which spellings of a word are common; only words with at
  # least one common spelling are imported.
  def common?(word)
    Array(word["kanji"]).any? { |form| form["common"] } ||
      Array(word["kana"]).any? { |form| form["common"] }
  end

  def common_form(word, key)
    form = Array(word[key]).find { |candidate| candidate["common"] }
    return nil if form.nil?

    form["text"].to_s.presence
  end

  def first_gloss(word)
    Array(word["sense"]).flat_map { |sense| Array(sense["gloss"]) }.first.to_s.presence
  end

  def parse_words
    data = JSON.parse(@path.read)
    data.is_a?(Hash) ? Array(data["words"]) : Array(data)
  end
end
