class CreateScenes < ActiveRecord::Migration[8.1]
  def change
    create_table :scenes do |t|
      t.string :setting
      t.text :description
      t.string :level
      t.references :character, null: false, foreign_key: true

      t.timestamps
    end
  end
end
