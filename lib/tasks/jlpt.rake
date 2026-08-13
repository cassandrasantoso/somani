require "json"

namespace :jlpt do
  desc "Import db/data/jlpt/*.json into jlpt_entries"
  task import: :environment do
    # N1 first so the easiest level wins when a word appears on two lists
    (1..5).each do |level|
      path = Rails.root.join("db/data/jlpt/n#{level}.json")
      next puts("N#{level}: #{path.basename} missing") unless path.exist?

      data  = JSON.parse(path.read)
      words = data.is_a?(Hash) ? data["words"] : data
      count = 0

      ActiveRecord::Base.transaction do
        words.each do |w|
          content = w["word"].presence || w["furigana"].presence # kana-only words
          next if content.blank?

          JlptEntry.find_or_initialize_by(content: content, entry_type: "word")
                   .update!(reading: w["furigana"], meaning: w["meaning"],
                            level: "N#{level}")
          count += 1
        end
      end

      puts "N#{level}: #{count} words"
    end

    # Katakana and hiragana words have no separate furigana — a kana word is
    # its own reading, so views never have to handle a nil.
    filled = JlptEntry.where(entry_type: "word", reading: [nil, ""])
                      .update_all("reading = content")

    puts "backfilled #{filled} kana-only readings"
    puts "jlpt_entries: #{JlptEntry.count} total"
  end
end
