class FeedbacksController < ApplicationController
  # story 8 — one feedbacks row per message
  def show
    @message = Message.find(params[:message_id])
    authorize @message, :show? # authorize the parent: feedback may be nil
    @feedback = @message.feedback
  end
end
