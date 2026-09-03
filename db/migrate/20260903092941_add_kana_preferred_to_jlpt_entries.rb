class AddKanaPreferredToJlptEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :jlpt_entries, :kana_preferred, :boolean
  end
end
