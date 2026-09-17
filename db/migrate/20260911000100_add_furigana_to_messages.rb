class AddFuriganaToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :furigana, :jsonb
  end
end
