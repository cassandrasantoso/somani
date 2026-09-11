require "test_helper"

class ReadingAttemptsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(email: "attempt-test@example.com", password: "password123", username: "attempttest")
    @upload = Upload.new(user: @user, media_type: "document", extracted_text: "文章です。")
    @upload.file.attach(
      io: File.open(Rails.root.join("public/icon.png")),
      filename: "icon.png",
      content_type: "image/png"
    )
    @upload.save!

    @passage = @upload.reading_passages.create!(
      text: "今日はいい天気です。公園を散歩しました。", position: 1, char_count: 19,
      questions: [
        { "q" => "Where did they walk?", "options" => %w[park school station home], "answer" => 0, "kind" => "detail" },
        { "q" => "How was the weather?", "options" => %w[rainy sunny snowy windy], "answer" => 1, "kind" => "detail" }
      ]
    )

    post user_session_path, params: { user: { email: @user.email, password: "password123" } }
  end

  test "grades server-side and records the attempt" do
    assert_difference "ReadingAttempt.count", 1 do
      post reading_passage_reading_attempts_path(@passage),
           params: { answers: [0, 1], duration_ms: 30_000 },
           as: :turbo_stream
    end

    attempt = ReadingAttempt.last
    assert_equal 100, attempt.comprehension
    assert_equal 38, attempt.wpm
    assert_equal @user, attempt.user
    assert_response :success
  end

  test "partial answers score partially" do
    post reading_passage_reading_attempts_path(@passage),
         params: { answers: [0, 3], duration_ms: 60_000 },
         as: :turbo_stream

    assert_equal 50, ReadingAttempt.last.comprehension
  end

  test "rejects another user's passage" do
    other = User.create!(email: "attempt-other@example.com", password: "password123", username: "attemptother")
    other_upload = Upload.new(user: other, media_type: "document", extracted_text: "他人の文章。")
    other_upload.file.attach(
      io: File.open(Rails.root.join("public/icon.png")),
      filename: "icon.png",
      content_type: "image/png"
    )
    other_upload.save!
    other_passage = other_upload.reading_passages.create!(text: "他人の文章です。", position: 1, char_count: 8,
                                                          questions: [])

    post reading_passage_reading_attempts_path(other_passage),
         params: { answers: [0], duration_ms: 10_000 },
         as: :turbo_stream

    assert_response :redirect
  end
end
