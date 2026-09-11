class CreateReadingPassagesAndAttempts < ActiveRecord::Migration[8.1]
  def change
    create_table :reading_passages do |t|
      t.bigint :upload_id, null: false
      t.text :text, null: false
      t.integer :position, null: false
      t.integer :char_count, null: false
      t.jsonb :questions, default: [], null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.index [:upload_id, :position], unique: true
    end

    create_table :reading_attempts do |t|
      t.bigint :user_id, null: false
      t.bigint :reading_passage_id, null: false
      t.integer :duration_ms, null: false
      t.integer :wpm, null: false
      t.integer :comprehension, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.index [:user_id, :reading_passage_id]
      t.index :user_id
    end

    add_foreign_key :reading_passages, :uploads
    add_foreign_key :reading_attempts, :users
    add_foreign_key :reading_attempts, :reading_passages
  end
end
