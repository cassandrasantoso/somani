class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  def home
    @scenes = Scene.includes(:character)
    @uploads = current_user&.uploads&.order(created_at: :desc)&.limit(5)
  end
end
