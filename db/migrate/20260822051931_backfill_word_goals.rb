class BackfillWordGoals < ActiveRecord::Migration[8.1]
  def up
    Adventure.find_each do |adventure|
      adventure.upload.saved_words.find_each do |word|
        WordGoal.find_or_create_by!(adventure: adventure, saved_word: word) do |g|
          g.target = adventure.goal_per_word
        end
      end
    end
  end

  def down
    WordGoal.delete_all
  end
end
