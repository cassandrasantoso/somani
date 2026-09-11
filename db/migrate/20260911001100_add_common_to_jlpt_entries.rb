class AddCommonToJlptEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :jlpt_entries, :common, :boolean, default: false, null: false
  end
end
