class AddEmbeddingToScenes < ActiveRecord::Migration[8.1]
  def change
    enable_extension "vector"

    add_column :scenes, :embedding, :vector, limit: 768
  end
end
