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

  teardown do
    Rails.cache.delete("jlpt/entry_contents")
  end
end
