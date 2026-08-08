class CreateAdventures < ActiveRecord::Migration[8.1]
  def change
    create_table :adventures do |t|
      t.string :title
      t.string :status
      t.references :scene, null: false, foreign_key: true
      t.references :upload, null: false, foreign_key: true

      t.timestamps
    end
  end
end
