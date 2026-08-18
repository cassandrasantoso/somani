class AddGoalTrackingToAdventures < ActiveRecord::Migration[8.1]
  def change
    add_column :adventures, :goal_per_word, :integer, default: 5, null:false
    add_column :adventures, :goal_reached_at, :datetime
    add_column :adventures, :goal_dismissed_at, :datetime
  end
end
