class SendRemindersJob < ApplicationJob
  queue_as :default

  WINDOW_MINUTES = 15

  # Scheduled every 15 minutes (config/recurring.yml). Each user's
  # reminder_time is matched in their OWN time zone, so 9:00 means 9:00
  # wherever they are. last_reminder_sent_at guards against a re-run
  # sending twice.
  def perform(now = Time.current)
    User.where(reminder_enabled: true)
        .where.not(reminder_time: nil)
        .where("last_reminder_sent_at IS NULL OR last_reminder_sent_at < :cutoff", cutoff: now - 1.hour)
        .find_each do |user|
      next unless in_window?(user, now)

      due_count = user.saved_words.due.count
      next if due_count.zero?

      ReminderMailer.daily_reminder(user, due_count).deliver_later
      user.touch(:last_reminder_sent_at)
    end
  end

  private

  def in_window?(user, now)
    reminder = user.reminder_time
    return false if reminder.blank?

    zone = ActiveSupport::TimeZone[user.time_zone.to_s] || ActiveSupport::TimeZone["UTC"]
    local = now.in_time_zone(zone)
    window_start = local.min - (local.min % WINDOW_MINUTES)

    reminder.hour == local.hour &&
      reminder.min >= window_start &&
      reminder.min < window_start + WINDOW_MINUTES
  end
end
