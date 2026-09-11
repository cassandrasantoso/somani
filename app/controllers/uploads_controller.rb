class UploadsController < ApplicationController
  before_action :set_upload, only: %i[show extract destroy]

  def index
    @uploads = policy_scope(Upload).includes(adventures: :scene).order(created_at: :desc)
  end

  def show
    authorize @upload
    @saved_words = @upload.saved_words
    @matched_entries = @upload.matched_jlpt_entries
    @already_saved_surfaces = current_user.saved_words.pluck(:surface)
    @word_targets = @upload.word_targets
  end

  def new
    @upload = Upload.new
    authorize @upload
  end

  def create
    @upload = Upload.new(upload_params)
    @upload.user = current_user
    authorize @upload

    if @upload.save
      # Created scene-less (see Adventure#draft?) so the show page has an
      # adventure id to attach the word-target form to before the learner
      # has picked words and an AI scene gets chosen.
      @upload.adventures.create!(status: "active")

      StoreUploadOnCloudinaryJob.perform_later(@upload)
      ExtractUploadTextJob.perform_later(@upload)

      redirect_to @upload, notice: "Upload successful."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def extract
    authorize @upload
    return redirect_to @upload, alert: "This upload has already been read." if @upload.ready?

    @upload.update!(extraction_status: :pending)
    ExtractUploadTextJob.perform_later(@upload)

    redirect_to @upload, notice: "Reading your upload…"
  end

  def destroy
    authorize @upload
    @upload.destroy
    redirect_to uploads_path, notice: "Upload deleted.", status: :see_other
  end

  private

  def set_upload
    @upload = Upload.find(params[:id])
  end

  def upload_params
    params.require(:upload).permit(:file)
  end
end
