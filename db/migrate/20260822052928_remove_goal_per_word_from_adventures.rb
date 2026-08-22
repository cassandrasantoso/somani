class RemoveGoalPerWordFromAdventures < ActiveRecord::Migration[8.1]
  def change
    remove_column :adventures, :goal_per_word, :integer, default: 5, null: false
  end
end
