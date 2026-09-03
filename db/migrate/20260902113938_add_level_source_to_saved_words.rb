class AddLevelSourceToSavedWords < ActiveRecord::Migration[8.1]
  def change
    add_column :saved_words, :level_source, :string
    add_column :saved_words, :category, :string

    reversible do |dir|
      dir.up do
        SavedWord.where(level_source: nil).where.not(jlpt_entry_id: nil).update_all(level_source: "jlpt")
      end
    end
  end
end
