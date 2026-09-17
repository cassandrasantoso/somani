class StoreUploadOnCloudinaryJob < ApplicationJob
  queue_as :default

  discard_on ActiveJob::DeserializationError

  def perform(upload)
    return if upload.file_location.present?

    upload.file.blob.open do |file|
      value = Cloudinary::Uploader.upload(file.path, folder: "somani/media", resource_type: "auto")
      upload.update!(file_location: value["url"])
    end
  end
end
