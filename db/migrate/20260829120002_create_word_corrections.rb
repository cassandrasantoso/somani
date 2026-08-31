class CreateWordCorrections < ActiveRecord::Migration[8.1]
  def change
    create_table :word_corrections do |t|
      t.references :feedback, null: false, foreign_key: true

      # Nullable on purpose — see below.
      t.references :saved_word, foreign_key: { on_delete: :nullify }

      # Denormalised so per-learner queries don't join
      # feedback → message → adventure → upload → user.
      t.references :user, null: false, foreign_key: true

      # Denormalised so cross-learner aggregation is one index scan, and so a
      # deleted saved_word doesn't take the row's meaning with it.
      t.string :surface, null: false
      t.string :kind,    null: false
      t.text   :wrote,   null: false
      t.text   :better,  null: false
      t.text   :why

      t.timestamps
    end

    add_index :word_corrections, %i[surface kind]
    add_index :word_corrections, %i[user_id surface]
  end
end
