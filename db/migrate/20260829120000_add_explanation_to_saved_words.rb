class AddExplanationToSavedWords < ActiveRecord::Migration[8.1]
  def change
    add_column :saved_words, :explanation, :text
  end
end
