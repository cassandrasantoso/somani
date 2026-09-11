class VerifyJlptEntriesJob < ApplicationJob
  queue_as :default

  limits_concurrency to: 1, key: "jisho"

  BATCH_SIZE = 5
  GAP = 40.seconds

  # The dictionary grind: every 15 minutes (config/recurring.yml) this
  # verifies the next batch of never-verified entries against jisho, most
  # used by learners first. The single-entry VerifyJlptLevelJob handles
  # words as they are saved; this one walks the long tail so coverage
  # stops depending on what users happen to save.
  def perform
    batch = JlptEntry.words.where(verified_at: nil)
                     .left_joins(:saved_words)
                     .group(:id)
                     .order(Arel.sql("COUNT(saved_words.id) DESC"), :id)
                     .limit(BATCH_SIZE)

    batch.each do |entry|
      respect_crawl_delay
      Rails.cache.write("jisho:last_call_at", Time.current)

      result = JishoLevelVerifier.call(entry)
      next unless result.status == :corrected

      SyncSavedWordLevels.call(entry)
      Rails.logger.info(
        "VerifyJlptEntriesJob #{entry.content}: #{result.from} -> #{result.to} (jisho #{result.tags.inspect})"
      )
    end
  rescue StandardError => e
    Rails.logger.warn("VerifyJlptEntriesJob: #{e.class}: #{e.message}")
  end

  private

  def respect_crawl_delay
    last = Rails.cache.read("jisho:last_call_at")
    remaining = last ? GAP - (Time.current - last) : 0
    sleep(remaining) if remaining.positive?
  end
end
