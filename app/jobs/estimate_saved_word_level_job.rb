class EstimateSavedWordLevelJob < ApplicationJob
  queue_as :default

  retry_on Faraday::TooManyRequestsError, wait: :polynomially_longer, attempts: 5
  discard_on ActiveJob::DeserializationError

  # Words found in the seeded dictionary are leveled at save time by lookup.
  # This job is for everything else: the estimator grades the word, the
  # dictionary learns it as a new entry, and jisho verification is queued so
  # the guess gets corrected into a real level over time.
  def perform(saved_word)
    return if saved_word.jlpt_entry.present?
    return if saved_word.level_source == "user"
    # Pure-katakana words not already in the dictionary are loanwords —
    # phonetic, outside what JLPT levels measure. The estimator guesses
    # "uncommon = N1" for them; don't let it.
    return if saved_word.surface.match?(/\A[\p{Katakana}ー・\s]+\z/)

    result = WordLevelEstimator.call(
      saved_word.surface,
      reading: saved_word.reading,
      meaning: saved_word.meaning
    )
    return if result.nil? || !result[:in_scope] || result[:level].blank?

    entry = JlptEntry.find_or_initialize_by(content: saved_word.surface, entry_type: "word")
    entry.update!(
      reading: saved_word.reading.presence || entry.reading,
      meaning: saved_word.meaning.presence || entry.meaning,
      level: result[:level],
      level_source: "estimate"
    )

    saved_word.update!(level: result[:level], level_source: "estimate", jlpt_entry: entry)

    VerifyJlptLevelJob.perform_later(entry)
  rescue Faraday::TooManyRequestsError
    raise
  rescue StandardError => e
    Rails.logger.warn("EstimateSavedWordLevelJob #{saved_word.id}: #{e.class}: #{e.message}")
  end
end
