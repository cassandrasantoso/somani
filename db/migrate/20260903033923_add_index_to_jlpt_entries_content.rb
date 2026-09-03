class AddIndexToJlptEntriesContent < ActiveRecord::Migration[8.1]
  def change
    add_index :jlpt_entries, [:entry_type, :content]
  end
end
