require "test_helper"

class SavedWordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "saved-words-test@example.com", password: "password123", username: "savedwordtester")
    @upload = Upload.new(user: @user, media_type: "photo")
    @upload.file.attach(
      io: File.open(Rails.root.join("public/icon.png")),
      filename: "icon.png",
      content_type: "image/png"
    )
    @upload.save!

    post user_session_path, params: { user: { email: @user.email, password: "password123" } }
  end

  test "create sets a word target on the upload's draft adventure" do
    post upload_saved_words_path(@upload), params: {
      saved_word: { surface: "食べる", reading: "たべる", meaning: "to eat", level: "N5" },
      target: "7"
    }

    saved_word = @user.saved_words.find_by!(surface: "食べる")
    adventure = @upload.adventures.find_by(scene_id: nil)

    assert adventure
    assert_equal 7, adventure.word_goals.find_by(saved_word: saved_word).target
  end

  test "create clamps an out-of-range target instead of failing" do
    post upload_saved_words_path(@upload), params: {
      saved_word: { surface: "食べる", reading: "たべる", meaning: "to eat", level: "N5" },
      target: "999"
    }

    saved_word = @user.saved_words.find_by!(surface: "食べる")
    adventure = @upload.adventures.find_by(scene_id: nil)

    assert_equal WordGoal::RANGE.last, adventure.word_goals.find_by(saved_word: saved_word).target
  end

  test "create without a target does not build a word goal" do
    post upload_saved_words_path(@upload), params: {
      saved_word: { surface: "食べる", reading: "たべる", meaning: "to eat", level: "N5" }
    }

    assert_equal 0, WordGoal.count
  end
end
