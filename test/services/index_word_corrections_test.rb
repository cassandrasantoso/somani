require "test_helper"

class IndexWordCorrectionsTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @user = User.create!(email: "revoke-test@example.com", password: "password123", username: "revoketest")
    @upload = Upload.new(user: @user, media_type: "document")
    @upload.file.attach(
      io: File.open(Rails.root.join("public/icon.png")),
      filename: "icon.png",
      content_type: "image/png"
    )
    @upload.save!

    character = Character.create!(name: "Revoke Tester", persona: "A friend.", voice: "ja-JP-NanamiNeural")
    scene = Scene.create!(character: character, setting: "A cafe",
                          description: "A quiet cafe.", level: "N3", source: :seed)
    @adventure = Adventure.create!(upload: @upload, scene: scene, status: "active")

    @word = SavedWord.create!(user: @user, surface: "為替", reading: "かわせ", meaning: "exchange rate", level: "N2")
    UploadedWord.create!(upload: @upload, saved_word: @word)
    @adventure.word_goals.create!(saved_word: @word, target: 1)

    @message = @adventure.messages.create!(role: "user", body: "為替のレートを昨日から変わりました。")
    CreditWordUsage.call(@message)
  end

  def feedback_with(corrections, on_word: true)
    @message.word_usages.update_all(status: "pending")
    feedback = @message.create_feedback!(
      assessment: "Test", level_estimate: "N3", coherence: "responsive", corrections: corrections
    )
    feedback
  end

  test "keeps the credit when the word survives the correction unchanged" do
    feedback_with([{
      "kind" => "grammar",
      "wrote" => "為替のレートを昨日から変わりました",
      "better" => "為替のレートが昨日から変わりました",
      "why" => "Subject takes が",
      "on_practice_word" => true,
      "practice_word" => "為替"
    }])

    IndexWordCorrections.call(@message.feedback)

    assert_equal "pending", @message.word_usages.reload.first.status
    assert WordCorrection.exists?(saved_word: @word, feedback: @message.feedback)
  end

  test "revokes when the word is substituted away in the correction" do
    feedback_with([{
      "kind" => "vocabulary",
      "wrote" => "為替を教えてください",
      "better" => "レートを教えてください",
      "why" => "Wrong word here",
      "on_practice_word" => true,
      "practice_word" => "為替"
    }])

    IndexWordCorrections.call(@message.feedback)

    assert_equal "revoked", @message.word_usages.reload.first.status
  end

  test "keeps the credit when attached grammar is wrong but the word is produced" do
    message = @adventure.messages.create!(role: "user", body: "寿司を食べるました。")
    saved = SavedWord.create!(user: @user, surface: "食べる", reading: "たべる", meaning: "to eat", level: "N5")
    UploadedWord.create!(upload: @upload, saved_word: saved)
    message.word_usages.create!(adventure: @adventure, saved_word: saved, status: "pending")

    feedback = message.create_feedback!(
      assessment: "Test", level_estimate: "N5", coherence: "responsive",
      corrections: [{
        "kind" => "grammar",
        "wrote" => "寿司を食べるました",
        "better" => "寿司を食べました",
        "why" => "Mixed dictionary form with polite past",
        "on_practice_word" => true,
        "practice_word" => "食べる"
      }]
    )

    IndexWordCorrections.call(feedback)

    assert_equal "pending", message.word_usages.reload.find_by(saved_word: saved).status
    assert WordCorrection.exists?(saved_word: saved, feedback: feedback)
  end
end
