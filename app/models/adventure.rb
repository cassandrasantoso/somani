class Adventure < ApplicationRecord
  STATUSES = %w[active completed].freeze

  belongs_to :scene
  belongs_to :upload
  has_many :messages, dependent: :destroy
  has_many :word_usages, dependent: :destroy

  delegate :user, to: :upload # so policies can say record.user
  has_one :character, through: :scene

  validates :status, inclusion: { in: STATUSES }

  # the words this adventure is judged against
  def target_words
    upload.saved_words.includes(:jlpt_entry)
  end

  # how many times each word has been used (word_id -> times_used)
  # counted by the database in one go, not one query per word
  def usage_counts
    word_usages.group(:saved_word_id).count
  end

  def goal_met?
    words = target_words.to_a
    return false if words.empty?

    counts = usage_counts
    words.all? { |w| counts.fetch(w.id, 0) >= goal_per_word }
  end

  def check_goal!
    return if goal_reached_at? || !goal_met?

    update!(goal_reached_at: Time.current)
  end

  # show the banner
  def prompt_goal?
    goal_reached_at? && goal_dismissed_at.nil? && status == "active"
  end

  def re_evaluate_goal!
    update!(goal_reached_at: (Time.current if goal_met?), goal_dismissed_at: nil)
  end
end
