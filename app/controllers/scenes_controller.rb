class ScenesController < ApplicationController
  def index
    @scenes = policy_scope(Scene).includes(:character)
  end

  def show
    @scene = Scene.find(params[:id])
    authorize @scene
  end
end
