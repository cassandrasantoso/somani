class CreateWordGoals < ActiveRecord::Migration[8.1]
  def change
    create_table :word_goals do |t|
      t.references :adventure,  null: false, foreign_key: true
      t.references :saved_word, null: false, foreign_key: true
      t.integer    :target,     null: false
      t.timestamps
    end

    add_index :word_goals, %i[adventure_id saved_word_id], unique: true
  end
end
