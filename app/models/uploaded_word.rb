class UploadedWord < ApplicationRecord
  belongs_to :upload
  belongs_to :saved_word

  validates :saved_word_id, uniqueness: { scope: :upload_id }
end
