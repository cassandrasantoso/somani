require "test_helper"

class GenerateUploadSceneJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @user = User.create!(email: "scene-test@example.com", password: "password123", username: "scenetest")
    @upload = Upload.new(user: @user, media_type: "document", extracted_text: "ラーメンは美味しい。味噌汁もあります。",
                         summary: "Oh, it looks like you are reading about restaurant menus!",
                         extraction_status: :ready)
    @upload.file.attach(
      io: File.open(Rails.root.join("public/icon.png")),
      filename: "icon.png",
      content_type: "image/png"
    )
    @upload.save!
    @n5_a = JlptEntry.create!(content: "ラーメン", reading: "らーめん", meaning: "ramen", level: "N5", entry_type: "word")
    @n5_b = JlptEntry.create!(content: "味噌汁", reading: "みそしる", meaning: "miso soup", level: "N5", entry_type: "word")
    @n3 = JlptEntry.create!(content: "美味しい", reading: "おいしい", meaning: "delicious", level: "N3", entry_type: "word")
  end

  def stub_class(klass, method, result)
    original = klass.method(method)
    klass.define_singleton_method(method) { |_arg, **| result }
    yield
  ensure
    klass.singleton_class.send(:define_method, method) do |*args, **kwargs, &block|
      original.call(*args, **kwargs, &block)
    end
  end

  test "creates a character and generated scene from the upload topic" do
    payload = {
      "character_name" => "Haruto",
      "persona" => "A cheerful cook at a small ramen shop.",
      "setting" => "a neighborhood ramen shop",
      "description" => "The learner has just sat down and is deciding what to order."
    }
    embedding = Array.new(EmbeddingService::DIMENSIONS) { 0.1 }

    stub_class(EmbeddingService, :generate, embedding) do
      stub_class(Llm, :generate_json, payload) do
        GenerateUploadSceneJob.perform_now(@upload)
      end
    end

    character = Character.find_by(name: "Haruto")
    assert_not_nil character
    assert_equal payload["persona"], character.persona
    assert_includes GenerateUploadSceneJob::VOICES, character.voice

    scene = character.scenes.last
    assert_equal "a neighborhood ramen shop", scene.setting
    assert_equal payload["description"], scene.description
    assert_equal "generated", scene.source
    assert_equal "N5", scene.level
  end

  test "skips when an existing scene already covers the topic" do
    embedding = Array.new(EmbeddingService::DIMENSIONS) { 0.1 }
    character = Character.create!(name: "Seed Chef", persona: "A cook.")
    character.scenes.create!(setting: "a ramen shop", level: "N5", source: :seed, embedding: embedding)

    stub_class(EmbeddingService, :generate, embedding) do
      GenerateUploadSceneJob.perform_now(@upload)
    end

    assert_equal 1, Scene.count
    assert_equal 1, Character.count
  end

  test "skips when the upload has no summary" do
    @upload.update!(summary: nil)

    assert_no_difference "Character.count" do
      GenerateUploadSceneJob.perform_now(@upload)
    end
  end

  test "skips when nothing in the upload matched the dictionary" do
    @upload.update!(extracted_text: "english only text")

    assert_no_difference "Character.count" do
      GenerateUploadSceneJob.perform_now(@upload)
    end
  end
end
