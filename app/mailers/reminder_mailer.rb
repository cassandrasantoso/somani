class ReminderMailer < ApplicationMailer
  def daily_reminder(user, due_count)
    @user = user
    @due_count = due_count

    mail to: user.email,
         subject: "Somani: #{pluralize(due_count, 'word')} waiting for review"
  end
end
