class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  def home
    @scenes = Scene.includes(:character)
    return unless user_signed_in?

    @uploads = current_user.uploads.order(created_at: :desc).limit(5)
    @active_adventures = current_user.adventures.where(status: "active")
     .includes(scene: :character).order(updated_at: :desc)

    saved_words = current_user.saved_words
    @vocabulary_level = saved_words.pick_most_common_level || Scene::DEFAULT_LEVEL
    # words not currently due stand in for "learned" vocabulary on the progress card
    @vocabulary_progress = saved_words.any? ? ((saved_words.count - saved_words.due.count) * 100.0 / saved_words.count).round : 0

    adventures = current_user.adventures
    @adventures_completed_pct = adventures.any? ? (adventures.where(status: "completed").count * 100.0 / adventures.count).round : 0
  end
end
