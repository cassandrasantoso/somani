class ReadingPassagesController < ApplicationController
  def show
    @passage = ReadingPassage.find(params[:id])
    authorize @passage.upload, :show?

    @attempt = ReadingAttempt.new
    @previous = current_user.reading_attempts
                            .where(reading_passage: @passage)
                            .order(created_at: :desc).first
  end
end
