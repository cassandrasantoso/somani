require "test_helper"

class UploadedWordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "uploaded-words-test@example.com", password: "password123",
                         username: "uploadedwordtester")
    @upload = Upload.new(user: @user, media_type: "photo")
    @upload.file.attach(
      io: File.open(Rails.root.join("public/icon.png")),
      filename: "icon.png",
      content_type: "image/png"
    )
    @upload.save!

    @saved_word = SavedWord.create!(user: @user, surface: "食べる", meaning: "to eat", level: "N5")
    @uploaded_word = UploadedWord.create!(upload: @upload, saved_word: @saved_word)

    post user_session_path, params: { user: { email: @user.email, password: "password123" } }
  end

  test "destroy re-renders the saved-word list via turbo_stream without error" do
    delete uploaded_word_path(@uploaded_word), as: :turbo_stream

    assert_response :success
  end

  test "destroy unlinks the word from the upload" do
    delete uploaded_word_path(@uploaded_word), as: :turbo_stream

    assert_not @upload.reload.saved_words.include?(@saved_word)
  end
end
