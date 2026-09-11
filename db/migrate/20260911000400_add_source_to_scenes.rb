class AddSourceToScenes < ActiveRecord::Migration[8.1]
  def change
    add_column :scenes, :source, :string, default: "seed", null: false
  end
end
