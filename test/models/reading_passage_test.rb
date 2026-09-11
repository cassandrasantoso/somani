require "test_helper"

class ReadingPassageTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "passage-test@example.com", password: "password123", username: "passagetest")
    @upload = Upload.new(user: @user, media_type: "document", extracted_text: "テスト")
    @upload.file.attach(
      io: File.open(Rails.root.join("public/icon.png")),
      filename: "icon.png",
      content_type: "image/png"
    )
    @upload.save!
  end

  test "splits at sentence boundaries within the size window" do
    sentence = "これは一文です。"
    text = sentence * 120

    passages = ReadingPassage.split_into_passages(text)

    assert passages.size > 1
    passages.each do |passage|
      assert passage.length >= ReadingPassage::MIN_PASSAGE_CHARS
      assert passage.length <= ReadingPassage::MAX_PASSAGE_CHARS + sentence.length
    end
  end

  test "short text becomes a single passage" do
    passages = ReadingPassage.split_into_passages("短いテキストです。")

    assert_equal 1, passages.size
    assert_equal "短いテキストです。", passages.first
  end

  test "blank text splits into nothing" do
    assert_empty ReadingPassage.split_into_passages("   \n  ")
  end

  test "generates passages and questions for an upload" do
    payload = {
      "questions" => [
        { "q" => "What is the passage about?", "options" => %w[a b c d], "answer" => 1, "kind" => "main_idea" },
        { "q" => "What did the writer eat?", "options" => %w[a b c d], "answer" => 0, "kind" => "detail" },
        { "q" => "What does 美味しい mean here?", "options" => %w[a b c d], "answer" => 2, "kind" => "vocab" }
      ]
    }

    original = Llm.method(:generate_json)
    Llm.define_singleton_method(:generate_json) { |_prompt, **| payload }
    GenerateReadingDrillJob.perform_now(@upload)
    Llm.singleton_class.send(:define_method, :generate_json) do |*args, **kwargs, &block|
      original.call(*args, **kwargs, &block)
    end

    passages = @upload.reading_passages.order(:position)
    assert_equal 1, passages.size
    assert_equal 1, passages.first.position
    assert_equal payload["questions"], passages.first.questions
  ensure
    Llm.singleton_class.send(:define_method, :generate_json) do |*args, **kwargs, &block|
      original.call(*args, **kwargs, &block)
    end
  end
end
