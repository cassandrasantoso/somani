require "test_helper"

class SendRemindersJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  def setup
    @now = Time.zone.parse("2026-09-11 09:00:00")
  end

  test "emails users whose reminder falls in this window and who have due words" do
    user = User.create!(email: "reminder-test@example.com", password: "password123", username: "remindertest",
                        reminder_enabled: true, reminder_time: Time.zone.parse("09:10"))
    user.saved_words.create!(surface: "食べる", meaning: "to eat", next_review_at: 1.day.ago)

    assert_enqueued_email_with ReminderMailer, :daily_reminder, args: [user, 1] do
      SendRemindersJob.perform_now(@now)
    end

    assert_not_nil user.reload.last_reminder_sent_at
  end

  test "skips users with no due words" do
    User.create!(email: "quiet@example.com", password: "password123", username: "quiettest",
                 reminder_enabled: true, reminder_time: Time.zone.parse("09:10"))

    assert_no_enqueued_emails do
      SendRemindersJob.perform_now(@now)
    end
  end

  test "skips users outside the window and reminders that are off" do
    User.create!(email: "later@example.com", password: "password123", username: "latertest",
                 reminder_enabled: true, reminder_time: Time.zone.parse("10:30"))
    User.create!(email: "off@example.com", password: "password123", username: "offtest",
                 reminder_enabled: false, reminder_time: Time.zone.parse("09:10"))

    assert_no_enqueued_emails do
      SendRemindersJob.perform_now(@now)
    end
  end

  test "does not send twice within the hour" do
    user = User.create!(email: "once@example.com", password: "password123", username: "oncetest",
                        reminder_enabled: true, reminder_time: Time.zone.parse("09:10"),
                        last_reminder_sent_at: 5.minutes.ago)
    user.saved_words.create!(surface: "飲む", meaning: "to drink", next_review_at: 1.day.ago)

    assert_no_enqueued_emails do
      SendRemindersJob.perform_now(@now)
    end
  end
end
