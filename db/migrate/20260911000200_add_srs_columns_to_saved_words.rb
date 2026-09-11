class AddSrsColumnsToSavedWords < ActiveRecord::Migration[8.1]
  def change
    add_column :saved_words, :review_repetitions, :integer, default: 0, null: false
    add_column :saved_words, :review_interval_days, :integer
    add_column :saved_words, :review_ease, :decimal, precision: 3, scale: 2, default: 2.5, null: false
  end
end
