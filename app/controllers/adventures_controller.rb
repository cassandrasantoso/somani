class AdventuresController < ApplicationController
  before_action :set_adventure, only: %i[show update destroy continue]

  def index
    @adventures = policy_scope(Adventure).includes(:scene).order(created_at: :desc)
  end

  def show
    authorize @adventure
    @messages = @adventure.messages.chronological.includes(:feedback)
    @message  = Message.new
    @target_words = @adventure.target_words
    @usage_counts = @adventure.usage_counts
    @goal_targets = @adventure.goal_targets
  end

  def new
    @upload = current_user.uploads.find(params[:upload_id])
    authorize @upload, :start_adventure?

    @adventure = @upload.adventures.new
    @upload.saved_words.each do |word|
      @adventure.word_goals.build(saved_word: word, target: WordGoal::DEFAULT_TARGET)
    end

    @scenes = Scene.includes(:character).order_by_relevance_to(@upload)
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
      @scenes = Scene.includes(:character).order_by_relevance_to(@upload)
      existing = @adventure.word_goals.map(&:saved_word_id)
      (@upload.saved_words.pluck(:id) - existing).each do |id|
        @adventure.word_goals.build(saved_word_id: id, target: WordGoal::DEFAULT_TARGET)
      end
      render :new, status: :unprocessable_entity
    end
  end

  # story 9 — the storyline ends
  def update
    authorize @adventure
    if @adventure.update(adventure_params)
      redirect_to @adventure, notice: "Adventure complete."
    else
      @messages     = @adventure.messages.chronological.includes(:feedback)
      @message      = Message.new
      @target_words = @adventure.target_words
      @usage_counts = @adventure.usage_counts
      @goal_targets = @adventure.goal_targets
      render :show, status: :unprocessable_entity
    end
  end

  # story 15 - delete an adventure
  def destroy
    authorize @adventure
    @adventure.destroy
    redirect_to adventures_path, notice: "Adventure deleted.", status: :see_other
  end

  def continue
    authorize @adventure, :update?
    @adventure.update!(goal_dismissed_at: Time.current)
    redirect_to @adventure, notice: "Keep going — no more reminders."
  end

  private

  def set_adventure
    @adventure = Adventure.find(params[:id])
  end

  def adventure_params
    params.require(:adventure).permit(:scene_id, :title, :status,
                                      word_goals_attributes: %i[saved_word_id target])
  end
end
