class SavedWordsController < ApplicationController
  before_action :set_saved_word, only: %i[show edit update destroy review]

  def index
    @saved_words = policy_scope(SavedWord).includes(adventures: { scene: :character })
    return unless params[:upload_id]

    @saved_words = @saved_words.joins(:uploads)
                               .where(uploads: { id: params[:upload_id] })
  end

  def new
    @upload = current_user.uploads.find(params[:upload_id])
    authorize @upload, :add_words?
    @saved_word = SavedWord.new
  end

  # Creates the word, looks the word up, then links it to this upload.
  def create
    @upload = current_user.uploads.find(params[:upload_id])
    authorize @upload, :add_words?

    surface   = saved_word_params[:surface].to_s.strip
    reference = lookup_entry(surface)

    # Scoped to this user. A global find_or_create_by(:surface) would share one
    # word row — and its review dates — between users.
    @saved_word = current_user.saved_words.find_or_initialize_by(surface: surface)

    # Anything the user typed wins; the reference fills the gaps.
    @saved_word.assign_attributes(
      reading: saved_word_params[:reading].presence || reference&.reading,
      meaning: saved_word_params[:meaning].presence || reference&.meaning,
      level: saved_word_params[:level].presence || reference&.level,
      jlpt_entry: reference
    )

    if @saved_word.save
      UploadedWord.find_or_create_by!(upload: @upload, saved_word: @saved_word)
      apply_word_target(@saved_word)
      notice = "「#{@saved_word.surface}」 saved."
      @saved_words = @upload.saved_words
      @matched_entries = @upload.matched_jlpt_entries
      @already_saved_surfaces = current_user.saved_words.pluck(:surface)
      @word_targets = @upload.word_targets

      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = notice }
        format.html { redirect_to @upload, notice: notice }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show   = authorize(@saved_word)
  def edit   = authorize(@saved_word)

  def update
    authorize @saved_word
    if @saved_word.update(saved_word_params)
      redirect_to saved_words_path, notice: "「#{@saved_word.surface}」updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def review
    authorize @saved_word, :update?
    @saved_word.update(last_reviewed_at: Time.current,
                       next_review_at: 1.day.from_now)
    redirect_back fallback_location: saved_words_path
  end

  def due
    @saved_words = policy_scope(SavedWord).due.includes(adventures: { scene: :character })
    render :index
  end

  def destroy
    authorize @saved_word
    @saved_word.destroy
    redirect_to saved_words_path, status: :see_other
  end

  private

  def set_saved_word
    @saved_word = current_user.saved_words.find(params[:id])
  end

  def saved_word_params
    params.require(:saved_word).permit(:surface, :reading, :level, :meaning)
  end

  def lookup_entry(surface)
    return if surface.blank?

    JlptEntry.find_by(content: surface, entry_type: "word") ||
      JlptEntry.find_by(reading: surface, entry_type: "word")
  end

  # The word's practice target for this upload's (not yet started) adventure —
  # set here, at save time, instead of in a separate step before the adventure starts.
  def apply_word_target(saved_word)
    target = params[:target].to_i
    return unless target.positive?

    adventure = @upload.draft_adventure || @upload.adventures.create!(status: "active")
    adventure.word_goals.find_or_initialize_by(saved_word: saved_word)
             .update!(target: target.clamp(WordGoal::RANGE))
  end
end
