class CreateCharacters < ActiveRecord::Migration[8.1]
  def change
    create_table :characters do |t|
      t.string :name
      t.text :persona
      t.string :voice

      t.timestamps
    end
  end
end
