require "test_helper"

class JmdictImportTest < ActiveSupport::TestCase
  def setup
    @path = Rails.root.join("tmp/test_jmdict.json")
    JlptEntry.create!(content: "既存", reading: "きぞん", meaning: "existing", level: "N3", entry_type: "word")

    File.write(@path, JSON.generate({
      "words" => [
        { "kanji" => [{ "text" => "既存", "common" => true }],
          "kana" => [{ "text" => "きぞん", "common" => true }],
          "sense" => [{ "gloss" => ["existing"] }] },
        { "kanji" => [{ "text" => "瞬間試験", "common" => true }],
          "kana" => [{ "text" => "しゅんかんしけん", "common" => true }],
          "sense" => [{ "gloss" => ["moment", "instant"] }] },
        { "kanji" => [{ "text" => "珍妙", "common" => false }],
          "kana" => [{ "text" => "ちんみょう", "common" => false }],
          "sense" => [{ "gloss" => ["curious"] }] },
        { "kanji" => [],
          "kana" => [{ "text" => "コーヒー試験", "common" => true }],
          "sense" => [{ "gloss" => ["coffee"] }] },
        { "kanji" => [{ "text" => "本日試験", "common" => true }],
          "kana" => [{ "text" => "ほんじつしけん", "common" => false }],
          "sense" => [{ "gloss" => ["this day"] }] }
      ]
    }))

    Rails.cache.delete("jlpt/entry_contents")
  end

  teardown do
    File.delete(@path) if File.exist?(@path)
    Rails.cache.delete("jlpt/entry_contents")
  end

  test "imports common words as level-less entries without duplicating" do
    result = JmdictImport.call(@path)

    assert_equal 3, result[:imported]

    moment = JlptEntry.find_by(content: "瞬間試験")
    assert_not_nil moment
    assert_nil moment.level
    assert_equal "jmdict", moment.level_source
    assert_equal "しゅんかんしけん", moment.reading
    assert_equal "moment", moment.meaning

    assert_nil JlptEntry.find_by(content: "珍妙")
    assert_equal 1, JlptEntry.where(content: "既存").count

    coffee = JlptEntry.find_by(content: "コーヒー試験")
    assert_not_nil coffee
    assert_equal "コーヒー試験", coffee.reading

    honjitsu = JlptEntry.find_by(content: "本日試験")
    assert_equal "ほんじつしけん", honjitsu.reading
  end

  test "imported entries are matchable in uploads" do
    JmdictImport.call(@path)

    user = User.create!(email: "jmdict-test@example.com", password: "password123", username: "jmdicttest")
    upload = Upload.new(user: user, media_type: "document", extracted_text: "その瞬間試験、驚きました。")
    upload.file.attach(
      io: File.open(Rails.root.join("public/icon.png")),
      filename: "icon.png",
      content_type: "image/png"
    )
    upload.save!

    assert_includes upload.reload.matched_jlpt_entries.map(&:content), "瞬間試験"
  end
end
