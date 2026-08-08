class Character < ApplicationRecord
  has_many :scenes, dependent: :restrict_with_error
end
