# A jlpt_entry's level is the source of truth once jisho (or the estimator)
# has settled on it. Saved words hold their own copy, taken at save time —
# this pushes corrections out to every word that inherited its level,
# never the ones a learner chose themselves.
class SyncSavedWordLevels
  def self.call(jlpt_entry)
    SavedWord.where(jlpt_entry: jlpt_entry, level_source: %w[jlpt estimate])
             .update_all(level: jlpt_entry.level, updated_at: Time.current)
  end
end
