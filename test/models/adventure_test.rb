require "test_helper"

class AdventureTest < ActiveSupport::TestCase
  def build_upload
    user = User.create!(email: "adventure-test@example.com", password: "password123", username: "advtester")
    upload = Upload.new(user: user, media_type: "photo")
    upload.file.attach(
      io: File.open(Rails.root.join("public/icon.png")),
      filename: "icon.png",
      content_type: "image/png"
    )
    upload.save!
    upload
  end

  test "can be created without a scene" do
    upload = build_upload
    adventure = Adventure.new(upload: upload, status: "active")

    assert adventure.valid?
    assert adventure.save
  end

  test "draft? is true only while scene is unset" do
    upload = build_upload
    adventure = Adventure.create!(upload: upload, status: "active")

    assert adventure.draft?

    character = Character.create!(name: "Test")
    scene = Scene.create!(character: character, setting: "A cafe", level: "N4")
    adventure.update!(scene: scene)

    assert_not adventure.draft?
  end

  test "started scope excludes scene-less adventures" do
    upload = build_upload
    draft = Adventure.create!(upload: upload, status: "active")

    character = Character.create!(name: "Test")
    scene = Scene.create!(character: character, setting: "A cafe", level: "N4")
    started = Adventure.create!(upload: upload, status: "active", scene: scene)

    assert_not_includes Adventure.started, draft
    assert_includes Adventure.started, started
  end
end
