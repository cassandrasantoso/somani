class MakeReadingAttemptWpmNullable < ActiveRecord::Migration[8.1]
  def up
    change_column_null :reading_attempts, :wpm, true
  end

  def down
    change_column_null :reading_attempts, :wpm, false
  end
end
