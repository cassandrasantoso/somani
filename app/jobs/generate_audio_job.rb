# app/jobs/generate_audio_job.rb
class GenerateAudioJob < ApplicationJob
  queue_as :default

  def perform(message)
    character = message.adventure.scene.character
    audio_data = AzureTextToSpeech.synthesize(message.body, voice_name: character.voice)

    message.audio.attach(
      io: StringIO.new(audio_data),
      filename: "message_#{message.id}.mp3",
      content_type: "audio/mpeg"
    )
  end
end
