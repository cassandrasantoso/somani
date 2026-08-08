class MakeJlptEntryOptionalOnSavedWords < ActiveRecord::Migration[8.1]
  def change
    change_column_null :saved_words, :jlpt_entry_id, true
  end
end
