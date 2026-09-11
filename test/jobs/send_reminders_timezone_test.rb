require "test_helper"

class SendRemindersTimezoneTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  test "matches the reminder window in the user's own time zone" do
    tokyo = User.create!(email: "tokyo@example.com", password: "password123", username: "tokyotest",
                         reminder_enabled: true, reminder_time: Time.zone.parse("09:10"),
                         time_zone: "Asia/Tokyo")
    tokyo.saved_words.create!(surface: "食べる", meaning: "to eat", next_review_at: 1.day.ago)

    # 09:10 in Tokyo is 00:10 UTC
    utc_midnight_ten = Time.utc(2026, 9, 11, 0, 10).in_time_zone

    assert_enqueued_email_with ReminderMailer, :daily_reminder, args: [tokyo, 1] do
      SendRemindersJob.perform_now(utc_midnight_ten)
    end
  end

  test "does not fire when the window only matches in another zone" do
    tokyo = User.create!(email: "tokyo2@example.com", password: "password123", username: "tokyotest2",
                         reminder_enabled: true, reminder_time: Time.zone.parse("09:10"),
                         time_zone: "Asia/Tokyo")
    tokyo.saved_words.create!(surface: "飲む", meaning: "to drink", next_review_at: 1.day.ago)

    # 09:10 UTC is 18:10 in Tokyo — no match
    utc_morning = Time.utc(2026, 9, 11, 9, 10).in_time_zone

    assert_no_enqueued_emails do
      SendRemindersJob.perform_now(utc_morning)
    end
  end

  test "unknown zone strings fall back to UTC instead of raising" do
    user = User.create!(email: "brokenzone@example.com", password: "password123", username: "brokenzone",
                        reminder_enabled: true, reminder_time: Time.zone.parse("09:10"),
                        time_zone: "Mars/Olympus")
    user.saved_words.create!(surface: "行く", meaning: "to go", next_review_at: 1.day.ago)

    assert_nothing_raised do
      SendRemindersJob.perform_now(Time.utc(2026, 9, 11, 9, 0).in_time_zone)
    end
  end
end
