require "gemini-ai"
require "base64"

class UploadsController < ApplicationController
  before_action :set_upload, only: %i[show destroy]

  GEMINI_MODEL = "gemini-3.5-flash"

  def index
    @uploads = policy_scope(Upload).includes(adventures: :scene).order(created_at: :desc)
  end

  def show
    authorize @upload
    @saved_words = @upload.saved_words
    @matched_entries = @upload.matched_jlpt_entries
    @already_saved_surfaces = current_user.saved_words.pluck(:surface)
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
    cloudinary_value = Cloudinary::Uploader.upload(file.path, folder: "somani/media", resource_type: "auto")

    @upload.file_location = cloudinary_value["url"]
    if @upload.save
      text = extract_text(@upload)
      @upload.update!(extracted_text: text)
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

  # ↓ new — moved from ExtractContentJob
  def extract_text(upload)
    file = upload.file
    data = Base64.strict_encode64(file.download)

    response = gemini_client.generate_content({
                                                contents: [
                                                  {
                                                    role: "user",
                                                    parts: [
                                                      { text: prompt_for(upload.media_type) },
                                                      {
                                                        inline_data: {
                                                          mime_type: file.content_type,
                                                          data: data
                                                        }
                                                      }
                                                    ]
                                                  }
                                                ]
                                              })

    response.dig("candidates", 0, "content", "parts", 0, "text").to_s.strip
  end

  def prompt_for(media_type)
    case media_type
    when "photo"
      "Extract and transcribe any Japanese text visible in this image, exactly as written. Return only the extracted text, no commentary."
    when "document"
      "Extract the Japanese text content of this document, exactly as written. Return only the extracted text, no commentary."
    when "audio"
      "Transcribe the Japanese speech in this audio accurately. Return only the transcript, no commentary."
    end
  end

  def gemini_client
    Gemini.new(
      credentials: {
        service: "generative-language-api",
        api_key: ENV.fetch("GEMINI_API_KEY")
      },
      options: { model: GEMINI_MODEL }
    )
  end
end
