class AddReminderTrackingToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :last_reminder_sent_at, :datetime
  end
end
