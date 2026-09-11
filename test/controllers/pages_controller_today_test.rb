require "test_helper"

class PagesControllerTodayTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(email: "today-test@example.com", password: "password123", username: "todaytest")
    post user_session_path, params: { user: { email: @user.email, password: "password123" } }
  end

  test "home shows the due word count in the today card" do
    @user.saved_words.create!(surface: "食べる", meaning: "to eat", next_review_at: 1.day.ago)

    get root_path

    assert_response :success
    assert_select ".today-card__value", text: "1"
    assert_select ".today-card__label", text: "words due for review"
  end

  test "home shows the caught-up state when nothing is due" do
    get root_path

    assert_select ".today-card__item--empty"
  end

  test "home links to the most recent upload with a drill" do
    upload = Upload.new(user: @user, media_type: "document", extracted_text: "テストテキスト。")
    upload.file.attach(
      io: File.open(Rails.root.join("public/icon.png")),
      filename: "icon.png",
      content_type: "image/png"
    )
    upload.save!
    upload.reading_passages.create!(text: "テストテキスト。", position: 1, char_count: 7, questions: [])

    get root_path

    assert_select "a[href=?]", upload_reading_drill_path(upload)
  end
end
