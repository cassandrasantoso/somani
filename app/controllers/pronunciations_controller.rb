class PronunciationsController < ApplicationController
  skip_after_action :verify_authorized

  DEFAULT_VOICE = "ja-JP-NanamiNeural"

  def show
    text = params[:text].to_s.strip
    return head :bad_request if text.blank?

    audio_data = AzureTextToSpeech.synthesize(text, voice_name: DEFAULT_VOICE)
    send_data audio_data, type: "audio/mpeg", disposition: "inline"
  end
end
