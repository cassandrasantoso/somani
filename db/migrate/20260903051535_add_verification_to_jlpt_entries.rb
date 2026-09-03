class AddVerificationToJlptEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :jlpt_entries, :level_source, :string
    add_column :jlpt_entries, :verified_at, :datetime
    add_column :jlpt_entries, :original_level, :string
  end
end
