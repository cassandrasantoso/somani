class CreateJlptEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :jlpt_entries do |t|
      t.string :entry_type
      t.string :content
      t.string :reading
      t.string :level
      t.text :meaning

      t.timestamps
    end
  end
end
