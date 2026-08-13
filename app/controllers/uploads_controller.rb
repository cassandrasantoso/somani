class UploadsController < ApplicationController
  before_action :set_upload, only: %i[show destroy]

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
    file = upload_params[:file]
    @upload = Upload.new(upload_params)
    @upload.user = current_user
    authorize @upload
    cloudinary_value = Cloudinary::Uploader.upload(file.path, folder: "somani/media")

    @upload.file_location = cloudinary_value["url"]
    if @upload.save
      redirect_to @upload, notice: "Upload successful."
    else
      render :new, status: :unprocessable_entity
    end
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
