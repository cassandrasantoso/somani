class CreateUploads < ActiveRecord::Migration[8.1]
  def change
    create_table :uploads do |t|
      t.string :media_type
      t.text :extracted_text
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
