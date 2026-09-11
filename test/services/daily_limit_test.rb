require "test_helper"

class DailyLimitTest < ActiveSupport::TestCase
  def with_env(key, value)
    original = ENV[key]
    ENV[key] = value
    yield
  ensure
    ENV[key] = original
  end

  def setup
    @user = User.create!(email: "limit-test@example.com", password: "password123", username: "limittest")
    @upload = Upload.new(user: @user, media_type: "document")
    @upload.file.attach(
      io: File.open(Rails.root.join("public/icon.png")),
      filename: "icon.png",
      content_type: "image/png"
    )
    @upload.save!
    @adventure = @upload.adventures.create!(status: "active")
  end

  test "counts only the user's own messages from today" do
    other = User.create!(email: "other-limit@example.com", password: "password123", username: "otherlimit")
    other_upload = Upload.new(user: other, media_type: "document")
    other_upload.file.attach(
      io: File.open(Rails.root.join("public/icon.png")),
      filename: "icon.png",
      content_type: "image/png"
    )
    other_upload.save!
    other_adventure = other_upload.adventures.create!(status: "active")

    3.times { @adventure.messages.create!(role: "user", body: "こんにちは。") }
    2.times { other_adventure.messages.create!(role: "user", body: "こんにちは。") }

    assert_equal 3, DailyLimit.messages_today(@user)
    assert_equal 2, DailyLimit.messages_today(other)
  end

  test "limit is exceeded only once the daily message count reaches it" do
    with_env("DAILY_MESSAGE_LIMIT", "2") do
      2.times { @adventure.messages.create!(role: "user", body: "こんにちは。") }

      assert DailyLimit.message_exceeded?(@user)

      assert_not DailyLimit.upload_exceeded?(@user)
    end
  end

  test "upload limit counts today's uploads only" do
    with_env("DAILY_UPLOAD_LIMIT", "2") do
      assert_not DailyLimit.upload_exceeded?(@user)

      extra = Upload.new(user: @user, media_type: "document")
      extra.file.attach(
        io: File.open(Rails.root.join("public/icon.png")),
        filename: "icon.png",
        content_type: "image/png"
      )
      extra.save!

      assert DailyLimit.upload_exceeded?(@user)
    end
  end

  test "yesterday's messages do not count toward today's limit" do
    with_env("DAILY_MESSAGE_LIMIT", "1") do
      message = @adventure.messages.create!(role: "user", body: "昨日のメッセージです。")
      message.update_column(:created_at, 2.days.ago)

      assert_not DailyLimit.message_exceeded?(@user)
    end
  end
end
