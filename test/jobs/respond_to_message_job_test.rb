require "test_helper"

class RespondToMessageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @user = User.create!(email: "respond-test@example.com", password: "password123", username: "respondtest")
    @upload = Upload.new(user: @user, media_type: "document")
    @upload.file.attach(
      io: File.open(Rails.root.join("public/icon.png")),
      filename: "icon.png",
      content_type: "image/png"
    )
    @upload.save!

    @character = Character.create!(name: "Test Character", persona: "A friendly barista.",
                                   voice: "ja-JP-NanamiNeural")
    @scene = Scene.create!(character: @character, setting: "A cafe",
                           description: "A quiet neighborhood coffee shop.", level: "N5", source: :seed)
    @adventure = Adventure.create!(upload: @upload, scene: @scene, status: "active")
    @message = @adventure.messages.create!(role: "user", body: "こんにちは、お元気ですか。")
  end

  def stub_streaming(text_chunks)
    original = Llm.method(:stream_conversation)
    Llm.define_singleton_method(:stream_conversation) do |_contents, system_instruction: nil, &block|
      accumulated = +""
      text_chunks.each { |chunk| accumulated << chunk }
      text_chunks.each_with_index { |chunk, i| block.call(chunk, text_chunks.first(i + 1).join) }
      accumulated
    end
    yield
  ensure
    Llm.singleton_class.send(:define_method, :stream_conversation) do |*args, **kwargs, &block|
      original.call(*args, **kwargs, &block)
    end
  end

  test "streams the reply and stores the full text" do
    stub_streaming(["こん", "にちは！", "いい", "天気ですね。"]) do
      perform_enqueued_jobs(except: [GenerateAudioJob, GenerateFuriganaJob, ReviewMessageJob]) do
        RespondToMessageJob.perform_later(@message)
      end
    end

    reply = @adventure.messages.where(role: "assistant").last
    assert_not_nil reply
    assert_equal "こんにちは！いい天気ですね。", reply.body
  end

  test "queues audio, furigana and review after the reply" do
    stub_streaming(["こんにちは！"]) do
      perform_enqueued_jobs(except: [GenerateAudioJob, GenerateFuriganaJob, ReviewMessageJob]) do
        RespondToMessageJob.perform_later(@message)
      end

      assert_enqueued_with(job: GenerateAudioJob)
      assert_enqueued_with(job: GenerateFuriganaJob)
      assert_enqueued_with(job: ReviewMessageJob)
    end
  end

  test "falls back to a whole reply when streaming fails" do
    original_stream = Llm.method(:stream_conversation)
    original_generate = Llm.method(:generate_conversation)
    Llm.define_singleton_method(:stream_conversation) { |_contents, system_instruction: nil| raise "boom" }
    Llm.define_singleton_method(:generate_conversation) { |_contents, system_instruction: nil| "フォールバックです。" }

    perform_enqueued_jobs(except: [GenerateAudioJob, GenerateFuriganaJob, ReviewMessageJob]) do
      RespondToMessageJob.perform_later(@message)
    end

    reply = @adventure.messages.where(role: "assistant").last
    assert_equal "フォールバックです。", reply.body
  ensure
    Llm.singleton_class.send(:define_method, :stream_conversation) do |*args, **kwargs, &block|
      original_stream.call(*args, **kwargs, &block)
    end
    Llm.singleton_class.send(:define_method, :generate_conversation) do |*args, **kwargs, &block|
      original_generate.call(*args, **kwargs, &block)
    end
  end
end
