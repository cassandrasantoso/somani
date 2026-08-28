require "test_helper"

class UploadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "uploads-test@example.com", password: "password123", username: "uploadtester")
    @upload = Upload.new(user: @user, media_type: "photo")
    @upload.file.attach(
      io: File.open(Rails.root.join("public/icon.png")),
      filename: "icon.png",
      content_type: "image/png"
    )
    @upload.save!
    @upload.update!(file_location: "https://example.com/icon.png")

    @saved_word = SavedWord.create!(user: @user, surface: "食べる", meaning: "to eat", level: "N5")
    UploadedWord.create!(upload: @upload, saved_word: @saved_word)

    post user_session_path, params: { user: { email: @user.email, password: "password123" } }
  end

  test "show renders a word-target field in the save-word modal" do
    get upload_path(@upload)

    assert_response :success
    assert_select "select[name='target']" do
      assert_select "option", text: "1", count: 1
      assert_select "option[selected]", text: "1"
    end
  end

  test "show renders the start-adventure button once words are saved" do
    get upload_path(@upload)

    assert_response :success
    assert_select "form[action=?]", upload_adventures_path(@upload)
  end

  test "show wires the start-adventure button to a loading overlay" do
    get upload_path(@upload)

    assert_response :success
    assert_select "div[data-controller='upload-form']" do
      assert_select "form[action=?][data-action='submit->upload-form#showLoading']", upload_adventures_path(@upload)
      assert_select "div.upload-loading[data-upload-form-target='overlay'][hidden]"
    end
  end

  test "show renders an Edit button per saved word carrying its current target" do
    adventure = Adventure.create!(upload: @upload, status: "active")
    adventure.word_goals.create!(saved_word: @saved_word, target: 6)

    get upload_path(@upload)

    assert_response :success
    assert_select "button.saved-word__edit[data-surface=?][data-times=?]", @saved_word.surface, "6"
  end

  test "show defaults a saved word's Edit button target when no goal is set yet" do
    get upload_path(@upload)

    assert_response :success
    assert_select "button.saved-word__edit[data-surface=?][data-times=?]",
                  @saved_word.surface, WordGoal::DEFAULT_TARGET.to_s
  end

  test "show also makes the word text itself open the edit modal" do
    get upload_path(@upload)

    assert_response :success
    assert_select "button.saved-word__surface-btn[data-bs-target='#exampleModal'][data-surface=?]",
                  @saved_word.surface do
      assert_select "span.saved-word__surface", text: @saved_word.surface
    end
  end
end
