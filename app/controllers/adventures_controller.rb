class AdventuresController < ApplicationController
  before_action :set_adventure, only: %i[show update destroy]

  def index
    @adventures = policy_scope(Adventure).includes(:scene).order(created_at: :desc)
  end

  def show
    authorize @adventure
    @messages = @adventure.messages.chronological.includes(:feedback)
    @message  = Message.new
  end

  def new
    @upload = current_user.uploads.find(params[:upload_id])
    authorize @upload, :start_adventure?
    @adventure = @upload.adventures.new
    @scenes = Scene.includes(:character)
  end

  # Adventure has no user_id — build it through the upload, which is what the policy checks.
  def create
    @upload = current_user.uploads.find(params[:upload_id])
    @adventure = @upload.adventures.new(adventure_params)
    @adventure.status = "active"
    authorize @adventure

    if @adventure.save
      OpeningLineJob.perform_later(@adventure)
      redirect_to @adventure
    else
      @scenes = Scene.includes(:character)
      render :new, status: :unprocessable_entity
    end
  end

  # story 9 — the storyline ends
  def update
    authorize @adventure
    if @adventure.update(adventure_params)
      redirect_to @adventure, notice: "Adventure complete."
    else
      render :show, status: :unprocessable_entity
    end
  end

  # story 15 - delete an adventure
  def destroy
    authorize @adventure
    @adventure.destroy
    redirect_to adventures_path, notice: "Adventure deleted.", status: :see_other
  end

  private

  def set_adventure
    @adventure = Adventure.find(params[:id])
  end

  def adventure_params
    params.require(:adventure).permit(:scene_id, :title, :status)
  end
end
