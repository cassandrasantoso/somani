class Character < ApplicationRecord
  has_many :scenes, dependent: :restrict_with_error
  has_one_attached :image
end
