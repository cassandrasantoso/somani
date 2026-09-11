class ReadingPassagesController < ApplicationController
  DEFAULT_VOICE = "ja-JP-NanamiNeural"

  def show
    @passage = ReadingPassage.find(params[:id])
    authorize @passage.upload, :show?

    @attempt = ReadingAttempt.new
    @previous = current_user.reading_attempts
                            .where(reading_passage: @passage)
                            .order(created_at: :desc).first
  end

  # Listening practice: the passage spoken aloud. Synthesized once, then
  # served from the attachment — re-listening is free.
  def audio
    @passage = ReadingPassage.find(params[:id])
    authorize @passage.upload, :show?

    unless @passage.audio.attached?
      audio_data = AzureTextToSpeech.synthesize(@passage.text, voice_name: DEFAULT_VOICE)
      @passage.audio.attach(
        io: StringIO.new(audio_data),
        filename: "passage_#{@passage.id}.mp3",
        content_type: "audio/mpeg"
      )
    end

    redirect_to rails_blob_path(@passage.audio, disposition: "inline")
  rescue AzureTextToSpeech::Error => e
    Rails.logger.error("ReadingPassages#audio passage=#{@passage.id}: #{e.message}")
    head :service_unavailable
  end
end
