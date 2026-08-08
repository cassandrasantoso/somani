class CreateUploadedWords < ActiveRecord::Migration[8.1]
  def change
    create_table :uploaded_words do |t|
      t.references :upload, null: false, foreign_key: true
      t.references :saved_word, null: false, foreign_key: true

      t.timestamps
    end
  end
end
