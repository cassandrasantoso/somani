require "test_helper"

class ExtractUploadTextJobTest < ActiveSupport::TestCase
  test "strips spaces between Japanese characters from transcriptions" do
    assert_equal "味噌汁もあります、お茶",
                 ExtractUploadTextJob.normalize_japanese_spacing("味噌 汁 も あります 、 お茶")
  end

  test "keeps spaces in non-Japanese segments" do
    assert_equal "hello world ラーメンはおいしい",
                 ExtractUploadTextJob.normalize_japanese_spacing("hello world ラーメン は おいしい")
  end

  test "leaves already-clean text untouched" do
    assert_equal "ラーメンは美味しい。",
                 ExtractUploadTextJob.normalize_japanese_spacing("ラーメンは美味しい。")
  end
end
