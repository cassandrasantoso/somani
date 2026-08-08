class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :uploads, dependent: :destroy
  has_many :adventures, through: :uploads
  # this keeps user's words alive when an upload is deleted:
  has_many :saved_words, dependent: :destroy

  validates :username, presence: true, uniqueness: true
end
