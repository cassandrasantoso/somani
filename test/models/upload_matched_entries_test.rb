require "test_helper"

class UploadMatchedEntriesTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "matched-test@example.com", password: "password123", username: "matchedtest")
    @upload = Upload.new(user: @user, media_type: "document",
                         extracted_text: "ラーメンを食べる。水も飲みました。")
    @upload.file.attach(
      io: File.open(Rails.root.join("public/icon.png")),
      filename: "icon.png",
      content_type: "image/png"
    )
    @upload.save!

    JlptEntry.create!(content: "ラーメン", reading: "らーめん", meaning: "ramen", level: "N5", entry_type: "word")
    JlptEntry.create!(content: "水", reading: "みず", meaning: "water", level: "N5", entry_type: "word")
    JlptEntry.create!(content: "食べる", reading: "たべる", meaning: "to eat", level: "N5", entry_type: "word")
    JlptEntry.create!(content: "寿司", reading: "すし", meaning: "sushi", level: "N5", entry_type: "word")

    Rails.cache.delete("jlpt/entry_contents")
  end

  test "returns only dictionary words present in the text" do
    matched = @upload.matched_jlpt_entries.map(&:content)

    assert_includes matched, "ラーメン"
    assert_includes matched, "食べる"
    assert_not_includes matched, "寿司"
  end

  test "single-kana-character matches are not returned" do
    JlptEntry.create!(content: "を", reading: "を", meaning: "object particle", level: "N5", entry_type: "word")
    Rails.cache.delete("jlpt/entry_contents")

    assert_not_includes @upload.matched_jlpt_entries.map(&:content), "を"
  end

  test "N1 and N2 katakana loanwords are not matched" do
    JlptEntry.create!(content: "レギュラー", reading: "れぎゅらー", meaning: "regular", level: "N1", entry_type: "word")
    JlptEntry.create!(content: "ニャンテスト", reading: "にゃんてすと", meaning: "synthetic", level: "N2", entry_type: "word")
    Rails.cache.delete("jlpt/entry_contents")

    upload = Upload.new(user: @user, media_type: "document",
                        extracted_text: "レギュラーとニャンテストの話です。")
    upload.file.attach(
      io: File.open(Rails.root.join("public/icon.png")),
      filename: "icon.png",
      content_type: "image/png"
    )
    upload.save!

    matched = upload.reload.matched_jlpt_entries.map(&:content)
    assert_not_includes matched, "レギュラー"
    assert_not_includes matched, "ニャンテスト"
  end

  test "common loanwords at N3 to N5 still match" do
    JlptEntry.create!(content: "テレビ試験", reading: "てれびしけん", meaning: "tv", level: "N5", entry_type: "word")
    Rails.cache.delete("jlpt/entry_contents")

    upload = Upload.new(user: @user, media_type: "document",
                        extracted_text: "テレビ試験を見ました。")
    upload.file.attach(
      io: File.open(Rails.root.join("public/icon.png")),
      filename: "icon.png",
      content_type: "image/png"
    )
    upload.save!

    assert_includes upload.reload.matched_jlpt_entries.map(&:content), "テレビ試験"
  end

  test "estimator-graded entries stay out of matching until jisho verifies" do
    JlptEntry.create!(content: "推定語試験", reading: "すいていごしけん", meaning: "guess",
                     level: "N1", level_source: "estimate", entry_type: "word")
    Rails.cache.delete("jlpt/entry_contents")

    upload = Upload.new(user: @user, media_type: "document",
                        extracted_text: "推定語試験について話しましょう。")
    upload.file.attach(
      io: File.open(Rails.root.join("public/icon.png")),
      filename: "icon.png",
      content_type: "image/png"
    )
    upload.save!

    assert_not_includes upload.reload.matched_jlpt_entries.map(&:content), "推定語試験"

    JlptEntry.find_by(content: "推定語試験").update!(level: "N3", level_source: "jisho")
    Rails.cache.delete("jlpt/entry_contents")

    assert_includes upload.reload.matched_jlpt_entries.map(&:content), "推定語試験"
  end

  teardown do
    Rails.cache.delete("jlpt/entry_contents")
  end
end
