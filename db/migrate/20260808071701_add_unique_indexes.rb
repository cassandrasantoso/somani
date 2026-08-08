class AddUniqueIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :users, :username, unique: true
    add_index :saved_words, %i[user_id surface], unique: true
    add_index :uploaded_words, %i[upload_id saved_word_id], unique: true
  end
end
