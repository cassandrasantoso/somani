class CreateLlmCalls < ActiveRecord::Migration[8.1]
  def change
    create_table :llm_calls do |t|
      t.string :model, null: false
      t.string :operation, null: false
      t.integer :prompt_tokens
      t.integer :completion_tokens
      t.integer :total_tokens
      t.integer :duration_ms
      t.datetime :created_at, null: false
    end

    add_index :llm_calls, :created_at
    add_index :llm_calls, [:model, :operation]
  end
end
