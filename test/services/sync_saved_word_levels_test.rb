require "test_helper"

class SyncSavedWordLevelsTest < ActiveSupport::TestCase
  def setup
    @entry = JlptEntry.create!(content: "為替", reading: "かわせ", meaning: "exchange rate",
                               level: "N1", level_source: "jlpt")
  end

  def user(name)
    User.create!(email: "#{name}@sync-test.example.com", password: "password123", username: name)
  end

  test "pushes a corrected level to words that inherited it, never the learner's own" do
    inherited = SavedWord.create!(user: user("inherited"), surface: "為替", level: "N2",
                                  level_source: "jlpt", jlpt_entry: @entry)
    estimated = SavedWord.create!(user: user("estimated"), surface: "為替", level: "N2",
                                  level_source: "estimate", jlpt_entry: @entry)
    own = SavedWord.create!(user: user("own"), surface: "為替", level: "N3",
                            level_source: "user", jlpt_entry: @entry)

    @entry.update!(level: "N1")

    SyncSavedWordLevels.call(@entry)

    assert_equal "N1", inherited.reload.level
    assert_equal "N1", estimated.reload.level
    assert_equal "N3", own.reload.level
  end
end
