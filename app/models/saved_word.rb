class SavedWord < ApplicationRecord
  belongs_to :user
  belongs_to :jlpt_entry, optional: true
end
