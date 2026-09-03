class VerifyJlptLevelJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: "jisho"

  GAP = 40.seconds

  def perform(jlpt_entry)
    return if jlpt_entry.verified_at.present?

    # robots.txt says Crawl-delay: 40. Re-enqueue rather than sleep, so a burst
    # of saves neither holds workers nor hammers jisho.
    last = Rails.cache.read("jisho:last_call_at")
    return self.class.set(wait: GAP).perform_later(jlpt_entry) if last && Time.current - last < GAP

    Rails.cache.write("jisho:last_call_at", Time.current)

    result = JishoLevelVerifier.call(jlpt_entry)
    return unless result.status == :corrected

    Rails.logger.info("VerifyJlptLevelJob #{jlpt_entry.content}: #{result.from} -> #{result.to} (jisho #{result.tags.inspect})")
  rescue StandardError => e
    Rails.logger.warn("VerifyJlptLevelJob #{jlpt_entry.id}: #{e.class}: #{e.message}")
  end
end
