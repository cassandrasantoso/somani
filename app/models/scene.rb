class Scene < ApplicationRecord
  belongs_to :character
  has_many :adventures, dependent: :restrict_with_error
end
