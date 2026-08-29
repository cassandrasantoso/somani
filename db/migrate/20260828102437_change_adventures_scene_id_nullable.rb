class ChangeAdventuresSceneIdNullable < ActiveRecord::Migration[8.1]
  def change
    change_column_null :adventures, :scene_id, true
  end
end
