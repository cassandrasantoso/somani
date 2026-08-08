class CreateSavedWords < ActiveRecord::Migration[8.1]
  def change
    create_table :saved_words do |t|
      t.string :surface
      t.string :reading
      t.string :level
      t.text :meaning
      t.references :user, null: false, foreign_key: true
      t.references :jlpt_entry, null: false, foreign_key: true
      t.datetime :last_reviewed_at
      t.datetime :next_review_at

      t.timestamps
    end
  end
end
