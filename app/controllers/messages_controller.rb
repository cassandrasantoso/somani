class MessagesController < ApplicationController
  before_action :set_message, only: %i[show audio translate]

  # story 7 — saves the user's line, then hands off to the AI
  def create
    @adventure = Adventure.find(params[:adventure_id])
    @message = @adventure.messages.new(message_params.merge(role: "user"))
    authorize @message

    if @message.save
      RespondToMessageJob.perform_later(@message, mode: params[:mode])
      @message = @adventure.messages.new
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @adventure }
      end
    else
      redirect_to @adventure, alert: "Message couldn't be sent."
    end
  end

  def show
    authorize @message
  end

  # story 5 — the character speaking
  def audio
    authorize @message, :show?
    GenerateAudioJob.perform_now(@message) unless @message.audio.attached?
    redirect_to rails_blob_path(@message.audio, disposition: "inline")
  end

  # story 16 — click a message, translate it
  def translate
    authorize @message, :show?
    @translation = TranslateMessage.call(@message)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @message.adventure }
    end
  end

  private

  def set_message
    @message = Message.find(params[:id])
  end

  def message_params
    params.require(:message).permit(:body) # role is set server-side
  end
end
