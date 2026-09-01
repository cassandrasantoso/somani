class AddStatusToWordUsages < ActiveRecord::Migration[8.1]
  def change
    # Optimistic by default: credit lands on send, and only the review pass
    # seconds later can take it back.
    add_column :word_usages, :status, :string, null: false, default: "credited"
  end
end
