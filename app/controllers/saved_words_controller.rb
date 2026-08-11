class SavedWordsController < ApplicationController
  before_action :set_saved_word, only: %i[show edit update destroy review]

  def index
    @saved_words = policy_scope(SavedWord)
    return unless params[:upload_id]

    @saved_words = @saved_words.joins(:uploads)
                               .where(uploads: { id: params[:upload_id] })
  end

  def new
    @upload = current_user.uploads.find(params[:upload_id])
    authorize @upload, :add_words?
    @saved_word = SavedWord.new
  end

  # Creates the word, then links it to this upload.
  def create
    @upload = current_user.uploads.find(params[:upload_id])
    authorize @upload, :add_words?

    # Scoped to this user. A global find_or_create_by(:surface) would share one
    # word row — and its review dates — between users.
    @saved_word = current_user.saved_words
                              .find_or_initialize_by(surface: saved_word_params[:surface])
    @saved_word.assign_attributes(saved_word_params)

    if @saved_word.save
      UploadedWord.find_or_create_by!(upload: @upload, saved_word: @saved_word)
      redirect_to @upload, notice: "「#{@saved_word.surface}」 saved."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show   = authorize(@saved_word)
  def edit   = authorize(@saved_word)

  def update
    authorize @saved_word
    if @saved_word.update(saved_word_params)
      redirect_to @saved_word
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
    @saved_words = policy_scope(SavedWord).due
    render :index
  end

  def destroy
    authorize @saved_word
    @saved_word.destroy
    redirect_to saved_words_path, status: :see_other
  end

  private

  def set_saved_word
    @saved_word = SavedWord.find(params[:id])
  end

  def saved_word_params
    params.require(:saved_word).permit(:surface, :reading, :level, :meaning)
  end
end
