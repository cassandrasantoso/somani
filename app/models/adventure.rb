class Adventure < ApplicationRecord
  belongs_to :scene
  belongs_to :upload
end
