class AddModeToReadingAttempts < ActiveRecord::Migration[8.1]
  def change
    add_column :reading_attempts, :mode, :string, default: "reading", null: false
  end
end
