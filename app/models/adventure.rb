require "gemini-ai"

class Adventure < ApplicationRecord
  STATUSES = %w[active completed].freeze
  PROMPT_FOCUS_LIMIT = 4

  belongs_to :scene, optional: true
  belongs_to :upload
  has_many :messages, dependent: :destroy
  has_many :word_usages, dependent: :destroy
  has_many :word_goals, dependent: :destroy

  # created without a scene at upload time; a scene gets picked once the
  # learner submits word targets and the adventure actually starts
  scope :started, -> { where.not(scene_id: nil) }

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
  # Only credited rows. Revoked rows are kept deliberately
  # see IndexWordCorrections, but they must not count toward the goal.
  def usage_counts
    word_usages.credited.group(:saved_word_id).count
  end

  # { saved_word_id => times credit was taken back }. The near-miss signal:
  # the learner reached for the word and the shape was wrong.
  def revoked_counts
    word_usages.revoked.group(:saved_word_id).count
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

  def generate_title
    words = word_goals
            .includes(:saved_word)
            .map { |goal| goal.saved_word.surface }
            .join(", ")

    prompt = <<~PROMPT
      Create a short Japanese and English title for a Japanese-learning roleplay adventure.

      Character:
      #{scene.character.name}

      Scene:
      #{scene.setting}

      Scene description:
      #{scene.description}

      Vocabulary to practice:
      #{words}

      Requirements:
      - Short and natural
      - Around 3 to 6 Japanese characters and 3 to 4 English words
      - Relevant to the scene and vocabulary
      - Return only the title
      - Do not use quotation marks
      - Do not explain anything
    PROMPT

    generated_title = generate_title_with_gemini(prompt)

    update!(title: generated_title)
  end

  def active? = status == "active"

  def draft? = scene_id.nil?

  def past_goal?
    goal_reached_at.present?
  end

  # Both callers of these i.e. CreditWordUsage on send, IndexWordCorrections on revocation
  # need identical locals, so are stated here rather than being duplicated in two services.
  def broadcast_tracker
    broadcast_replace_to(
      self,
      target: "word-tracker",
      partial: "adventures/tracker",
      locals: { adventure: self,
                target_words: target_words,
                usage_counts: usage_counts,
                goal_targets: goal_targets }
    )
  end

  def broadcast_goal_banner
    broadcast_replace_to(
      self,
      target: "goal-banner",
      partial: "adventures/goal_banner",
      locals: { adventure: self }
    )
  end

  private

  def generate_title_with_gemini(prompt)
    client = Gemini.new(
      credentials: {
        service: "generative-language-api",
        api_key: ENV.fetch("GEMINI_API_KEY")
      },
      options: {
        model: ENV.fetch("GEMINI_MODEL")
      }
    )
    begin
      response = client.generate_content(
        {
          contents: [
            {
              role: "user",
              parts: [
                { text: prompt }
              ]
            }
          ]
        }
      )

      response
        .dig("candidates", 0, "content", "parts", 0, "text")
        .to_s
        .strip
    rescue StandardError => _e
      "Unable to generate title!"
    end
  end
end
