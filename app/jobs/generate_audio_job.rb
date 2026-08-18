# app/jobs/generate_audio_job.rb
require "faraday"

class GenerateAudioJob < ApplicationJob
  queue_as :default

  AZURE_TTS_URL = "https://%s.tts.speech.microsoft.com/cognitiveservices/v1"

  HD_VOICE_OVERRIDES = {
    "ja-JP-NanamiNeural" => "ja-JP-Nanami:DragonHDLatestNeural", # Yuki
    "ja-JP-KeitaNeural" => "ja-JP-Masaru:DragonHDLatestNeural"   # Takeshi
  }.freeze

  STANDARD_VOICE_OVERRIDES = {
    "ja-JP-AoiNeural" => "ja-JP-MayuNeural"
  }.freeze

  PROSODY_BY_VOICE = {
    "ja-JP-AoiNeural" => { rate: "+5%", pitch: "0%", volume: "loud" } # Hina: fast-paced, casual, pushy
  }.freeze

  DEFAULT_PROSODY = { rate: "0%", pitch: "0%", volume: "medium" }.freeze

  def perform(message)
    character = message.adventure.scene.character
    audio_data = synthesize_speech(message.body, character.voice)

    message.audio.attach(
      io: StringIO.new(audio_data),
      filename: "message_#{message.id}.mp3",
      content_type: "audio/mpeg"
    )
  end

  private

  def synthesize_speech(text, voice_name)
    connection = Faraday.new(url: azure_tts_url)

    response = connection.post do |req|
      req.headers["Ocp-Apim-Subscription-Key"] = ENV.fetch("AZURE_SPEECH_KEY")
      req.headers["Content-Type"] = "application/ssml+xml"
      req.headers["X-Microsoft-OutputFormat"] = "audio-16khz-32kbitrate-mono-mp3"
      req.headers["User-Agent"] = "Somani"
      req.body = ssml_for(text, voice_name)
    end

    raise "Azure TTS error: #{response.status} #{response.body}" unless response.success?

    response.body
  end

  def ssml_for(text, voice_name)
    hd_voice = HD_VOICE_OVERRIDES[voice_name]
    escaped_text = ERB::Util.html_escape(text)

    if hd_voice
      <<~SSML
        <speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xmlns:mstts='http://www.w3.org/2001/mstts' xml:lang='ja-JP'>
          <voice xml:lang='ja-JP' name='#{hd_voice}'>#{escaped_text}</voice>
        </speak>
      SSML
    else
      actual_voice = STANDARD_VOICE_OVERRIDES.fetch(voice_name, voice_name)
      prosody = PROSODY_BY_VOICE.fetch(voice_name, DEFAULT_PROSODY)
      <<~SSML
        <speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xmlns:mstts='http://www.w3.org/2001/mstts' xml:lang='ja-JP'>
          <voice xml:lang='ja-JP' name='#{actual_voice}'>
            <prosody rate='#{prosody[:rate]}' pitch='#{prosody[:pitch]}' volume='#{prosody[:volume]}'>#{escaped_text}</prosody>
          </voice>
        </speak>
      SSML
    end
  end

  def azure_tts_url
    format(AZURE_TTS_URL, ENV.fetch("AZURE_SPEECH_REGION"))
  end
end
