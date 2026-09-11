class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[home about]

  def about; end

  def home
    @scenes = Scene.includes(:character)
    return unless user_signed_in?

    @uploads = current_user.uploads.order(created_at: :desc).limit(5)
    @active_adventures = current_user.adventures.started.where(status: "active")
                                     .includes(scene: :character).order(updated_at: :desc)

    @adventures_completed_pct = current_user.adventures_completed_pct
    @due_words_count = current_user.saved_words.due.count
    @drill_uploads = current_user.uploads.joins(:reading_passages)
                                 .where.not(extracted_text: nil)
                                 .distinct.order(created_at: :desc)
  end
end
