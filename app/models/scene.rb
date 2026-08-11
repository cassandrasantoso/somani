class Scene < ApplicationRecord
  belongs_to :character
  has_many :adventures, dependent: :restrict_with_error

  DEFAULT_LEVEL = "N2".freeze

  # Orders scenes so ones matching the relevant JLPT level come first.
  # Prefers the level of words saved from this specific upload; falls back
  # to the user's overall saved_words history, then to N2 (the app's target level).
  def self.order_by_relevance_to(upload)
    level = upload.saved_words.pick_most_common_level ||
            upload.user.saved_words.pick_most_common_level ||
            DEFAULT_LEVEL

    order(Arel.sql("CASE WHEN level = #{connection.quote(level)} THEN 0 ELSE 1 END"))
  end
end
