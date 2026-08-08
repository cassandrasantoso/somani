class UploadedWord < ApplicationRecord
  belongs_to :upload
  belongs_to :saved_word
end
