class AddCoherenceToFeedbacks < ActiveRecord::Migration[8.1]
  def change
    # null = not assessed — either there was no previous turn to judge
    # against, or the model didn't return a usable value.
    add_column :feedbacks, :coherence, :string
    add_column :feedbacks, :coherence_note, :text

    add_index :feedbacks, :coherence
  end
end
