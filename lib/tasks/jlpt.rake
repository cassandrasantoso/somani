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

  desc "Score the level estimator against seeded words (read-only)"
  task eval_levels: :environment do
    sample = JlptEntry.words.where.not(level: nil).order("RANDOM()").limit(100)

    exact        = 0
    off_by_one   = 0
    out_of_scope = 0
    unscored     = 0
    errors       = 0
    rows = []

    sample.each do |entry|
      sleep 1 # throttle; this is ~100 calls

      guess =
        begin
          WordLevelEstimator.call(entry.content) # => { level:, in_scope:, category: } or nil
        rescue StandardError => e
          Rails.logger.warn("jlpt:eval_levels #{entry.content}: #{e.class}: #{e.message}")
          nil
        end

      if guess.nil?
        errors += 1
      elsif !guess[:in_scope]
        out_of_scope += 1
      elsif guess[:level].nil?
        unscored += 1
      elsif guess[:level] == entry.level
        exact += 1
      elsif (SavedWord::LEVEL_ENUM[guess[:level].to_sym].to_i -
            SavedWord::LEVEL_ENUM[entry.level.to_sym].to_i).abs == 1
        off_by_one += 1
      end

      rows << [entry.content, entry.level, guess&.dig(:level), guess&.dig(:in_scope)]
    end

    puts "exact:        #{exact}/#{sample.size}"
    puts "off-by-one:   #{off_by_one}/#{sample.size}"
    puts "out of scope (false negatives — every sampled word IS JLPT vocabulary): #{out_of_scope}/#{sample.size}"
    puts "in scope but no level returned: #{unscored}/#{sample.size}"
    puts "errors (unparseable response or API failure): #{errors}/#{sample.size}"
    puts "\nmisses:"
    rows.reject { |_c, actual, guess, _s| actual == guess }.each { |r| puts "  #{r.inspect}" }
  end
end
