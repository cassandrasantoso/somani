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


  def extract_from_image
    image = params[:image]
    return render json: { error: "No image provided" }, status: :bad_request unless image

    # Upload to Cloudinary for storage
    Cloudinary::Uploader.upload(image.path, folder: "billy/bill_scans")

    json_match = ai_parse_bill(image.path)

    if json_match
      render json: JSON.parse(json_match[0])
    else
      render json: { error: "Could not extract data from image", raw: text }, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "extract_from_image error: #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    render json: { error: e.message }, status: :unprocessable_entity
  end


end
