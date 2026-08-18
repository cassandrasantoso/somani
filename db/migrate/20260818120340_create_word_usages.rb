class CreateWordUsages < ActiveRecord::Migration[8.1]
  def change
    create_table :word_usages do |t|
      t.references :adventure, null: false, foreign_key: true
      t.references :saved_word, null: false, foreign_key: true
      t.references :message, null: false, foreign_key: true

      t.timestamps
    end

    # one credit per word per message — this is the anti-gaming rule
    add_index :word_usages, %i[message_id saved_word_id], unique: true
    add_index :word_usages, %i[adventure_id saved_word_id]
  end
end
