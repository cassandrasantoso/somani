class WordUsage < ApplicationRecord
  belongs_to :adventure
  belongs_to :saved_word
  belongs_to :message
end
