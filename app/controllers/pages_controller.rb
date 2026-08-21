class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  def home
    @scenes = Scene.includes(:character)
    return unless user_signed_in?

    @uploads = current_user.uploads.order(created_at: :desc).limit(5)
    @active_adventures = current_user.adventures.where(status: "active")
     .includes(scene: :character).order(updated_at: :desc)

    @vocabulary_level = Scene::DEFAULT_LEVEL

    # progress = how much of the *entire* N2 word list the user has covered —
    # either by adding it to their word bank (studied) or by using it in an
    # Adventure conversation (practiced) — against the full N2 dictionary,
    # not just the size of their own smaller saved-word list
    total_n2_words = JlptEntry.words.by_level(@vocabulary_level).count
    studied_n2_word_ids = current_user.saved_words
                                       .joins(:jlpt_entry)
                                       .merge(JlptEntry.words.by_level(@vocabulary_level))
                                       .distinct
                                       .pluck(:jlpt_entry_id)
    @vocabulary_progress = total_n2_words.zero? ? 0 : (studied_n2_word_ids.size * 100.0 / total_n2_words).round

    adventures = current_user.adventures
    @adventures_completed_pct = adventures.any? ? (adventures.where(status: "completed").count * 100.0 / adventures.count).round : 0
  end
end
