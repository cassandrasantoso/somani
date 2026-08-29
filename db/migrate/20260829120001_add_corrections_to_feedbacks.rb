class AddCorrectionsToFeedbacks < ActiveRecord::Migration[8.1]
  def change
    add_column :feedbacks, :corrections, :jsonb, default: []

    # has_one without a unique index permits duplicates under concurrent
    # retries. The job checks too; this makes it a constraint.
    remove_index :feedbacks, :message_id
    add_index    :feedbacks, :message_id, unique: true
  end
end
