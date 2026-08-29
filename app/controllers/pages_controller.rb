class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[home about]

  def about; end

  def home
    @scenes = Scene.includes(:character)
    return unless user_signed_in?

    @uploads = current_user.uploads.order(created_at: :desc).limit(5)
    @active_adventures = current_user.adventures.started.where(status: "active")
     .includes(scene: :character).order(updated_at: :desc)

    @vocabulary_level = current_user.vocabulary_level
    @vocabulary_progress = current_user.vocabulary_progress
    @adventures_completed_pct = current_user.adventures_completed_pct
  end
end
