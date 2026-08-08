class CreateFeedbacks < ActiveRecord::Migration[8.1]
  def change
    create_table :feedbacks do |t|
      t.text :assessment
      t.text :encouragement
      t.text :used_learned_words
      t.string :level_estimate
      t.references :message, null: false, foreign_key: true

      t.timestamps
    end
  end
end
