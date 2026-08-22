class WordGoal < ApplicationRecord
  DEFAULT_TARGET = 1
  RANGE          = (1..20)

  belongs_to :adventure
  belongs_to :saved_word

  validates :target,
            numericality: { only_integer: true,
                            greater_than_or_equal_to: RANGE.first,
                            less_than_or_equal_to: RANGE.last }

  validate :word_must_belong_to_adventure

  # Changing a target can complete the adventure, or un-complete it.
  after_save    :re_evaluate_adventure
  after_destroy :re_evaluate_adventure

  private

  # word_goals_attributes carries saved_word_id from the form, so without this
  # a crafted request could attach a target to a word the adventure never had.
  # target_words works on an unsaved adventure too — it reads through upload.
  def word_must_belong_to_adventure
    return if adventure.blank? || saved_word.blank?
    return if adventure.target_words.exists?(saved_word.id)

    errors.add(:saved_word, "isn't part of this adventure")
  end

  def re_evaluate_adventure
    adventure.re_evaluate_goal!
  end
end
