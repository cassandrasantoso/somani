class SendRemindersJob < ApplicationJob
  queue_as :default

  WINDOW_MINUTES = 15

  # Scheduled every 15 minutes (config/recurring.yml). Each run picks the
  # users whose reminder_time falls inside [now, now + 15), so every
  # configured time is covered exactly once a day. last_reminder_sent_at
  # guards against a re-run sending twice.
  def perform(now = Time.current)
    return if now.min % WINDOW_MINUTES != 0

    window_start = now.min
    window_end = now.min + WINDOW_MINUTES

    User.where(reminder_enabled: true)
        .where("EXTRACT(HOUR FROM reminder_time) = :hour
                AND EXTRACT(MINUTE FROM reminder_time) >= :start
                AND EXTRACT(MINUTE FROM reminder_time) < :end",
               hour: now.hour, start: window_start, end: window_end)
        .where("last_reminder_sent_at IS NULL OR last_reminder_sent_at < :cutoff", cutoff: now - 1.hour)
        .find_each do |user|
      due_count = user.saved_words.due.count
      next if due_count.zero?

      ReminderMailer.daily_reminder(user, due_count).deliver_later
      user.touch(:last_reminder_sent_at)
    end
  end
end
