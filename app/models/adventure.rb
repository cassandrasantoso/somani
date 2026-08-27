class Adventure < ApplicationRecord
  STATUSES = %w[active completed].freeze
  PROMPT_FOCUS_LIMIT = 4

  belongs_to :scene
  belongs_to :upload
  has_many :messages, dependent: :destroy
  has_many :word_usages, dependent: :destroy
  has_many :word_goals, dependent: :destroy

  # Blank target means "leave it at the default" — reject if skips the row
  # instead of storing a duplicate of WordGoal::DEFAULT_TARGET.
  accepts_nested_attributes_for :word_goals,
                                reject_if: ->(attrs) { attrs["target"].blank? }

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

  # { saved_word_id => target } for words with their own goal. Same shape as
  # usage_counts, so the view looks both up the same way.
  def goal_targets
    word_goals.pluck(:saved_word_id, :target).to_h
  end

  def goal_for(word)
    goal_targets.fetch(word.id, WordGoal::DEFAULT_TARGET)
  end

  def goal_met?
    words = target_words.to_a
    return false if words.empty?

    counts  = usage_counts
    targets = goal_targets

    words.all? { |w| counts.fetch(w.id, 0) >= targets.fetch(w.id, WordGoal::DEFAULT_TARGET) }
  end

  # called after ordinary word crediting — only ever moves reached_at forward,
  # never touches dismissed_at, so it can't re-open a banner the user dismissed
  def check_goal!
    return if goal_reached_at? || !goal_met?

    update!(goal_reached_at: Time.current)
  end

  # called when a WordGoal target changes — a changed target invalidates the
  # old verdict in both directions, so both timestamps get recomputed
  def re_evaluate_goal!
    update!(goal_reached_at: (Time.current if goal_met?), goal_dismissed_at: nil)
  end

  # show the banner
  def prompt_goal?
    goal_reached_at? && goal_dismissed_at.nil? && active?
  end

  # Words that still need credit, the ones furthest from their goal first.
  # As a word earns credit it drops down the list, so the next one comes up.
  def practice_words(limit: nil)
    counts  = usage_counts
    targets = goal_targets

    unfinished = target_words.to_a.reject do |w|
      counts.fetch(w.id, 0) >= targets.fetch(w.id, WordGoal::DEFAULT_TARGET)
    end

    words = unfinished.sort_by do |w|
      counts.fetch(w.id, 0) - targets.fetch(w.id, WordGoal::DEFAULT_TARGET)
    end
    limit ? words.first(limit) : words
  end

  # The vocabulary block both jobs paste into their prompt.
  # Returns "" when every word is finished, so the character just converses normally.
  def practice_brief(limit: PROMPT_FOCUS_LIMIT)
    words = practice_words(limit: limit)
    return "" if words.empty?

    words.map { |w| "・#{w.surface}（#{w.reading}）— #{w.meaning}" }.join("\n")
  end

  def active? = status == "active"

  def past_goal?
    goal_reached_at.present?
  end
end
