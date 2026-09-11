# app/jobs/generate_audio_job.rb
class GenerateAudioJob < ApplicationJob
  queue_as :default

  retry_on AzureTextToSpeech::Error, wait: :polynomially_longer, attempts: 3
  discard_on ActiveJob::DeserializationError

  def perform(message)
    return if message.audio.attached?

    character = message.adventure.scene.character
    audio_data = AzureTextToSpeech.synthesize(message.body, voice_name: character.voice)

    message.audio.attach(
      io: StringIO.new(audio_data),
      filename: "message_#{message.id}.mp3",
      content_type: "audio/mpeg"
    )
  end
end
