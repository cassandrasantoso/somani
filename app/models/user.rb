class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :uploads, dependent: :destroy
  has_many :adventures, through: :uploads
  # this keeps user's words alive when an upload is deleted:
  has_many :saved_words, dependent: :destroy
  has_one_attached :avatar

  has_many :active_friendships, class_name: "Friendship", foreign_key: :follower_id, dependent: :destroy
  has_many :following, through: :active_friendships, source: :followed
  has_many :passive_friendships, class_name: "Friendship", foreign_key: :followed_id, dependent: :destroy
  has_many :followers, through: :passive_friendships, source: :follower

  validates :username, presence: true, uniqueness: true

  def vocabulary_level
    Scene::DEFAULT_LEVEL
  end

  # progress = how much of the *entire* N2 word list the user has covered —
  # either by adding it to their word bank (studied) or by using it in an
  # Adventure conversation (practiced) — against the full N2 dictionary,
  # not just the size of their own smaller saved-word list
  def vocabulary_progress
    total_words = JlptEntry.words.by_level(vocabulary_level).count
    return 0 if total_words.zero?

    studied_word_count = saved_words
                         .joins(:jlpt_entry)
                         .merge(JlptEntry.words.by_level(vocabulary_level))
                         .distinct
                         .count(:jlpt_entry_id)
    (studied_word_count * 100.0 / total_words).round
  end

  def adventures_completed_pct
    started = adventures.started
    return 0 if started.none?

    (started.where(status: "completed").count * 100.0 / started.count).round
  end
end
