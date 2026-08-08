class AddDetailsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :username, :string
    add_column :users, :reminder_enabled, :boolean, default:false, null: false
    add_column :users, :reminder_time, :time
  end
end
