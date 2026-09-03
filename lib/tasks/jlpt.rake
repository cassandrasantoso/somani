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
    way_off      = 0
    out_of_scope = 0
    unscored     = 0
    errors       = 0
    rows = []

    sample.each_with_index do |entry, i|
      sleep 5 # throttle — Flash Lite is ~15 RPM; sleep 1 produced 40%+ 429s
      print "." if (i + 1) % 10 == 0 # progress every 10 words, so silence doesn't look like a hang

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
      else
        way_off += 1
      end

      rows << [entry.content, entry.level, guess&.dig(:level), guess&.dig(:in_scope)]
    end

    tallied = [exact, off_by_one, way_off, out_of_scope, unscored, errors].sum
    raise "counts sum to #{tallied}, expected #{sample.size}" unless tallied == sample.size

    puts "exact:        #{exact}/#{sample.size}"
    puts "off-by-one:   #{off_by_one}/#{sample.size}"
    puts "way off (2+ levels): #{way_off}/#{sample.size}"
    puts "out of scope (false negatives — every sampled word IS JLPT vocabulary): #{out_of_scope}/#{sample.size}"
    puts "in scope but no level returned: #{unscored}/#{sample.size}"
    puts "errors (unparseable response or API failure): #{errors}/#{sample.size}"
    puts "\nmisses:"
    rows.reject { |_c, actual, guess, _s| actual == guess }.each { |r| puts "  #{r.inspect}" }
  end

  desc "Audit the seed JSONs for internal inconsistencies (read-only, no API calls)"
  task audit: :environment do
    entries = []

    (1..5).each do |n|
      path = Rails.root.join("db/data/jlpt/n#{n}.json")
      next unless path.exist?

      data  = JSON.parse(path.read)
      words = data.is_a?(Hash) ? data["words"] : data
      words.each do |w|
        entries << { word: w["word"].to_s, furigana: w["furigana"].to_s,
                     meaning: w["meaning"].to_s, file_level: n, field_level: w["level"] }
      end
    end

    puts "total entries across files: #{entries.size}"

    mismatched = entries.reject { |e| e[:field_level] == e[:file_level] }
    puts "\n[1] level field != filename: #{mismatched.size}"
    mismatched.first(20).each { |e| puts "  #{e[:word]} in n#{e[:file_level]}.json says level #{e[:field_level]}" }

    by_word = entries.group_by { |e| e[:word].presence || e[:furigana] }

    cross = by_word.select { |_w, es| es.map { |e| e[:file_level] }.uniq.size > 1 }
    puts "\n[2] words at more than one level (import keeps the easiest): #{cross.size}"
    cross.first(20).each { |w, es| puts "  #{w}: levels #{es.map { |e| e[:file_level] }.sort.inspect}" }

    dupes = by_word.select { |_w, es| es.size > es.map { |e| e[:file_level] }.uniq.size }
    puts "\n[3] words duplicated within a single level: #{dupes.size}"

    multi = by_word.select { |_w, es| es.map { |e| e[:furigana] }.uniq.size > 1 }
    puts "\n[4] same written form, different readings (import keys on content — one silently wins): #{multi.size}"
    multi.first(20).each do |w, es|
      puts "  #{w}: " + es.map { |e| "#{e[:furigana]}(n#{e[:file_level]})" }.uniq.join(" / ")
    end

    variants = by_word.filter_map do |w, es|
      fur = es.first[:furigana]
      next if fur.blank? || fur == w || !by_word.key?(fur)

      [w, es.first[:file_level], fur, by_word[fur].first[:file_level]]
    end
    puts "\n[5] kanji form AND kana form both listed separately: #{variants.size}"
    variants.first(20).each { |kanji, kl, kana, kal| puts "  #{kanji}(n#{kl}) / #{kana}(n#{kal})" }

    puts "\n[6] blank word field: #{entries.count { |e| e[:word].blank? }}; " \
         "blank furigana: #{entries.count { |e| e[:furigana].blank? }}"

    singles = entries.select { |e| (e[:word].presence || e[:furigana]).length == 1 }
    puts "[7] single-character entries by level: " \
         "#{singles.group_by { |e| e[:file_level] }.transform_values(&:size).sort.to_h}"

    kana_only = /\A[\p{Hiragana}\p{Katakana}ー[[:space:]]]*\z/
    dirty = entries.reject { |e| e[:furigana].blank? || e[:furigana].match?(kana_only) }
    puts "\n[8] furigana containing non-kana characters: #{dirty.size}"
    dirty.first(20).each { |e| puts "  #{e[:word]}(n#{e[:file_level]}): #{e[:furigana].inspect}" }

    blank_with_kanji = entries.select { |e| e[:furigana].blank? && e[:word].match?(/\p{Han}/) }
    puts "\n[9] blank furigana but contains kanji (backfill sets reading = kanji): #{blank_with_kanji.size}"
    blank_with_kanji.first(20).each { |e| puts "  #{e[:word]}(n#{e[:file_level]})" }

    blank_meaning = entries.select { |e| e[:meaning].blank? }
    puts "\n[10] entries with no meaning (upstream issue #3 claims ~51): #{blank_meaning.size}"
    blank_meaning.first(20).each { |e| puts "  #{e[:word]}(n#{e[:file_level]})" }

    by_reading = entries.group_by { |e| e[:furigana] }
    okurigana = by_reading.select do |fur, es|
      fur.present? &&
        es.map { |e| e[:word] }.uniq.size > 1 &&
        es.map { |e| e[:word].gsub(/[\p{Hiragana}\p{Katakana}ー]/, "") }.uniq.size == 1
    end
    puts "\n[11] okurigana variants (same reading, same kanji, different kana): #{okurigana.size}"
    okurigana.first(20).each do |fur, es|
      puts "  #{fur}: #{es.map do |e|
        "#{e[:word]}(n#{e[:file_level]})"
      end.uniq.join(' / ')}"
    end
  end

  desc "Probe jisho for N seeded words. Respects robots.txt Crawl-delay: 40."
  task :probe_jisho, [:count] => :environment do |_t, args|
    require "net/http"
    require "uri"

    count  = (args[:count] || 10).to_i
    sample = JlptEntry.words.where(level: "N1").order("RANDOM()").limit(count)

    sample.each_with_index do |entry, i|
      uri = URI("https://jisho.org/api/v1/search/words?keyword=#{URI.encode_www_form_component(entry.content)}")
      req = Net::HTTP::Get.new(uri)
      # PUT A REAL CONTACT ADDRESS HERE before running.
      req["User-Agent"] = "Somani/1.0 (JLPT level audit; contact: you@example.com)"

      body = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }.body
      data = JSON.parse(body)["data"] || []

      hit = data.find do |d|
        Array(d["japanese"]).any? { |j| j["word"] == entry.content || j["reading"] == entry.content }
      end

      tags   = hit ? Array(hit["jlpt"]) : []
      common = hit ? hit["is_common"] : nil
      puts format("%-12s %-10s seed=%-3s jisho=%-26s common=%s",
                  entry.content, entry.reading, entry.level, tags.inspect, common.inspect)

      sleep 40 unless i == sample.size - 1
    end
  end
end
