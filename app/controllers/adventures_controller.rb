class AdventuresController < ApplicationController
  before_action :set_adventure, only: %i[show update destroy continue]

  def index
    @adventures = policy_scope(Adventure).includes(:scene).order(created_at: :desc)
  end

  def show
    raise ActiveRecord::RecordNotFound if @adventure.nil?

    authorize @adventure
    @messages = @adventure.messages.chronological.includes(:feedback)
    @message  = Message.new
    @target_words = @adventure.target_words
    @usage_counts = @adventure.usage_counts
    @goal_targets = @adventure.goal_targets
  end

  # Adventure has no user_id — build it through the upload, which is what the policy checks.
  def create
    @upload = current_user.uploads.find(params[:upload_id])

    # Stop here if there are no saved words
    if @upload.saved_words.empty?
      redirect_to @upload, alert: "Save at least one word before starting an adventure."
      return
    end

    @adventure = @upload.adventures.new(status: "active")

    @upload.saved_words.each do |word|
      @adventure.word_goals.build(
        saved_word: word,
        target: WordGoal::DEFAULT_TARGET
      )
    end

    selected_words = @adventure.word_goals.map(&:saved_word)
    best_scene = Scene.nearest_to_words(selected_words)

    @adventure.scene = best_scene

    authorize @adventure

    if @adventure.save
      GenerateTitleJob.perform_later(@adventure)
      OpeningLineJob.perform_later(@adventure)

      redirect_to @adventure
    else
      Rails.logger.error(
        "Adventure create failed (upload=#{@upload.id} user=#{current_user.id}): " \
        "#{@adventure.errors.full_messages.inspect}"
      )
      redirect_to @upload, alert: "Could not start adventure."
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
    @adventure = Adventure.find_by(id: params[:id])
  end

  def adventure_params
    params.require(:adventure).permit(:scene_id, :title, :status,
                                      word_goals_attributes: %i[saved_word_id target])
  end
end
