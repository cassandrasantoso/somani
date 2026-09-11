class ReadingDrillsController < ApplicationController
  def show
    @upload = Upload.find(params[:upload_id])
    authorize @upload, :show?
    @passages = @upload.reading_passages.order(:position)
    @attempts = current_user.reading_attempts.where(reading_passage: @passages).order(created_at: :desc)
  end

  # Generates the drill on demand — question generation costs a few lite
  # calls per upload, so it only runs for uploads the user actually drills.
  def create
    @upload = Upload.find(params[:upload_id])
    authorize @upload, :show?

    GenerateReadingDrillJob.perform_later(@upload) if @upload.reading_passages.none? && @upload.extracted_text.present?

    redirect_to upload_reading_drill_path(@upload), notice: "Preparing your reading drill…"
  end
end
