require "test_helper"

class AdventuresControllerTest < ActionDispatch::IntegrationTest
  # Stands in for Gemini.new so both EmbeddingService (used by Scene.nearest_to_words)
  # and Adventure#generate_title can run against real DB records with no network calls.
  class FakeGeminiClient
    def generate_content(_payload)
      { "candidates" => [{ "content" => { "parts" => [{ "text" => "A Generated Title" }] } }] }
    end

    def embed_content(_payload)
      { "embedding" => { "values" => Array.new(EmbeddingService::DIMENSIONS) { rand } } }
    end
  end

  setup do
    @user = User.create!(email: "adventures-test@example.com", password: "password123", username: "adventuretester")
    @upload = Upload.new(user: @user, media_type: "photo")
    @upload.file.attach(
      io: File.open(Rails.root.join("public/icon.png")),
      filename: "icon.png",
      content_type: "image/png"
    )
    @upload.save!

    @saved_word = SavedWord.create!(user: @user, surface: "食べる", meaning: "to eat", level: "N5")
    UploadedWord.create!(upload: @upload, saved_word: @saved_word)
    @draft = Adventure.create!(upload: @upload, status: "active")

    post user_session_path, params: { user: { email: @user.email, password: "password123" } }
  end

  # Minitest 6 dropped Minitest::Mock from this app's bundle, so Gemini.new is
  # swapped out by hand instead — same effect, no extra dependency.
  def stub_gemini
    Gemini.define_singleton_method(:new) { |*_args, **_kwargs| FakeGeminiClient.new }
    yield
  ensure
    Gemini.singleton_class.send(:remove_method, :new)
  end

  test "create finishes the draft adventure with an AI-picked scene, word targets already set" do
    @draft.word_goals.create!(saved_word: @saved_word, target: 5)

    stub_gemini do
      character = Character.create!(name: "Test Character")
      Scene.create!(character: character, setting: "A cafe", level: "N4").generate_embedding!

      post upload_adventures_path(@upload)
    end

    @draft.reload
    assert_redirected_to adventure_path(@draft)
    assert_not @draft.draft?
    assert_equal "A Generated Title", @draft.title
    assert_equal 5, @draft.word_goals.find_by(saved_word: @saved_word).target
  end

  test "create does not build another adventure when a draft already exists" do
    stub_gemini do
      character = Character.create!(name: "Test Character")
      Scene.create!(character: character, setting: "A cafe", level: "N4").generate_embedding!

      assert_no_difference "Adventure.count" do
        post upload_adventures_path(@upload)
      end
    end
  end

  # Regression test: scene is optional now (see Adventure#draft?), so a save
  # alone no longer catches Scene.nearest_to_words coming back empty — this
  # used to 500 inside generate_title (nil.character) instead of redirecting.
  test "create redirects instead of crashing when no scene matches" do
    stub_gemini do
      post upload_adventures_path(@upload)
    end

    assert_redirected_to @upload
    assert_equal "Could not find a matching scene. Please try again.", flash[:alert]
    assert @draft.reload.draft?
  end
end
