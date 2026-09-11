require "test_helper"

class GenerateFuriganaJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @user = User.create!(email: "furigana-test@example.com", password: "password123", username: "furiganatest")
    @upload = Upload.new(user: @user, media_type: "document")
    @upload.file.attach(
      io: File.open(Rails.root.join("public/icon.png")),
      filename: "icon.png",
      content_type: "image/png"
    )
    @upload.save!

    character = Character.create!(name: "Furigana Tester", persona: "A friend.", voice: "ja-JP-NanamiNeural")
    scene = Scene.create!(character: character, setting: "A cafe",
                          description: "A quiet cafe.", level: "N5", source: :seed)
    @adventure = Adventure.create!(upload: @upload, scene: scene, status: "active")
    @message = @adventure.messages.create!(role: "assistant", body: "今日はいい天気ですね。")
  end

  def stub_payload(payload)
    original = GeminiClient.method(:generate_json)
    GeminiClient.define_singleton_method(:generate_json) { |_prompt, **| payload }
    yield
  ensure
    GeminiClient.singleton_class.send(:define_method, :generate_json) do |*args, **kwargs, &block|
      original.call(*args, **kwargs, &block)
    end
  end

  test "stores segments that reconstruct the body exactly" do
    payload = {
      "segments" => [
        { "base" => "今日", "reading" => "きょう" },
        { "base" => "は" },
        { "base" => "いい" },
        { "base" => "天気", "reading" => "てんき" },
        { "base" => "ですね。" }
      ]
    }

    stub_payload(payload) do
      GenerateFuriganaJob.perform_now(@message)
    end

    @message.reload
    expected = [
      { "base" => "今日", "reading" => "きょう" },
      { "base" => "は", "reading" => nil },
      { "base" => "いい", "reading" => nil },
      { "base" => "天気", "reading" => "てんき" },
      { "base" => "ですね。", "reading" => nil }
    ]
    assert_equal expected, @message.furigana
  end

  test "leaves plain text when segments do not reconstruct the body" do
    stub_payload("segments" => [{ "base" => "別の", "reading" => "べつの" }]) do
      GenerateFuriganaJob.perform_now(@message)
    end

    assert_nil @message.reload.furigana
  end

  test "skips messages that already have furigana" do
    @message.update!(furigana: [{ "base" => "今日", "reading" => "きょう" }])

    stub_payload(nil) do
      GenerateFuriganaJob.perform_now(@message)
    end

    assert_equal 1, @message.reload.furigana.size
  end
end
