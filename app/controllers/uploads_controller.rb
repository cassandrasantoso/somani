class UploadsController < ApplicationController
  before_action :set_upload, only: %i[show destroy extract]

  def index
    @uploads = policy_scope(Upload).order(created_at: :desc)
  end

  def show
    authorize @upload
    @saved_words = @upload.saved_words
  end

  def new
    @upload = Upload.new
    authorize @upload
  end

  def create
    @upload = Upload.new(upload_params)
    @upload.user = current_user # before authorize
    authorize @upload

    if @upload.save
      ExtractContentJob.perform_later(@upload)
      redirect_to @upload, notice: "Analysing your upload..."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def extract
    authorize @upload, :update?
    ExtractContentJob.perform_later(@upload)
    redirect_to @upload, notice: "Re-analysing."
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
    params.require(:upload).permit(:media_type, :file) # no :user_id
  end
end
