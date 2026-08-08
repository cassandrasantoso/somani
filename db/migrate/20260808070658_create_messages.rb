class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.string :role
      t.text :body
      t.references :adventure, null: false, foreign_key: true

      t.timestamps
    end
  end
end
