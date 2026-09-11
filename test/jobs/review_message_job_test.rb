require "test_helper"

class ReviewMessageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @user = User.create!(email: "review-test@example.com", password: "password123", username: "reviewtest")
    @upload = Upload.new(user: @user, media_type: "document")
    @upload.file.attach(
      io: File.open(Rails.root.join("public/icon.png")),
      filename: "icon.png",
      content_type: "image/png"
    )
    @upload.save!

    @character = Character.create!(name: "Review Tester", persona: "A friend.", voice: "ja-JP-NanamiNeural")
    @scene = Scene.create!(character: @character, setting: "A cafe",
                           description: "A quiet cafe.", level: "N4", source: :seed)
    @adventure = Adventure.create!(upload: @upload, scene: @scene, status: "active")

    @word = SavedWord.create!(user: @user, surface: "為替", reading: "かわせ", meaning: "exchange rate", level: "N2")
    UploadedWord.create!(upload: @upload, saved_word: @word)
    @adventure.word_goals.create!(saved_word: @word, target: 2)

    @message = @adventure.messages.create!(role: "user", body: "為替のレートについて話しましょうか。")
  end

  def stub_review(payload)
    original = GeminiClient.method(:generate_json)
    GeminiClient.define_singleton_method(:generate_json) { |_prompt, **| payload }
    yield
  ensure
    GeminiClient.singleton_class.send(:define_method, :generate_json) do |*args, **kwargs, &block|
      original.call(*args, **kwargs, &block)
    end
  end

  test "credits practice words the review reports as used" do
    payload = {
      "assessment" => "Nice reach for a hard word.",
      "level_estimate" => "N3",
      "coherence" => nil,
      "coherence_note" => nil,
      "used_practice_words" => ["為替"],
      "corrections" => []
    }

    stub_review(payload) do
      perform_enqueued_jobs { ReviewMessageJob.perform_later(@message) }
    end

    usage = @message.word_usages.find_by(saved_word: @word)
    assert_not_nil usage
    assert_equal "credited", usage.status

    assert @adventure.reload.goal_targets[@word.id] = 2
    assert_equal 1, @adventure.usage_counts[@word.id]
  end

  test "ignores hallucinated words that are not practice words" do
    payload = {
      "assessment" => "Good.",
      "level_estimate" => "N3",
      "coherence" => nil,
      "coherence_note" => nil,
      "used_practice_words" => ["存在しない言葉"],
      "corrections" => []
    }

    stub_review(payload) do
      perform_enqueued_jobs { ReviewMessageJob.perform_later(@message) }
    end

    assert_empty @message.word_usages.reload
  end

  test "skips the job for trivial acknowledgements with no pending credit" do
    short = @adventure.messages.create!(role: "user", body: "はい")

    assert_no_enqueued_jobs do
      ReviewMessageJob.perform_now(short)
    end

    assert_nil short.feedback
  end
end
