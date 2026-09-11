require "test_helper"

class EstimateSavedWordLevelJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @user = User.create!(email: "estimate-test@example.com", password: "password123", username: "estimatetest")
  end

  def stub_estimator(result)
    WordLevelEstimator.define_singleton_method(:call) { |_surface, **| result }
    yield
  ensure
    WordLevelEstimator.singleton_class.send(:remove_method, :call)
  end

  test "grades an unlisted word, learns it as an entry, and queues verification" do
    saved_word = SavedWord.create!(user: @user, surface: "見積もり", reading: "みつもり", meaning: "quotation")

    stub_estimator(in_scope: true, level: "N3", category: nil) do
      perform_enqueued_jobs(except: VerifyJlptLevelJob) do
        EstimateSavedWordLevelJob.perform_later(saved_word)
      end
      assert_enqueued_with(job: VerifyJlptLevelJob)
    end

    saved_word.reload
    assert_equal "N3", saved_word.level
    assert_equal "estimate", saved_word.level_source

    entry = saved_word.jlpt_entry
    assert_not_nil entry
    assert_equal "N3", entry.level
    assert_equal "estimate", entry.level_source
    assert_equal "みつもり", entry.reading
  end

  test "does nothing for out-of-scope words" do
    saved_word = SavedWord.create!(user: @user, surface: "スターバックス", reading: "すたーばっくす")

    stub_estimator(in_scope: false, level: nil, category: "brand") do
      perform_enqueued_jobs { EstimateSavedWordLevelJob.perform_later(saved_word) }
    end

    saved_word.reload
    assert_nil saved_word.level
    assert_nil saved_word.jlpt_entry
    assert_nil JlptEntry.find_by(content: "スターバックス")
  end

  test "skips words the learner leveled themselves" do
    saved_word = SavedWord.create!(user: @user, surface: "特別", level: "N4", level_source: "user")

    assert_no_enqueued_jobs do
      EstimateSavedWordLevelJob.perform_now(saved_word)
    end

    assert_equal "N4", saved_word.reload.level
    assert_equal "user", saved_word.level_source
  end

  test "skips words already linked to a dictionary entry" do
    entry = JlptEntry.create!(content: "食べる", reading: "たべる", meaning: "to eat", level: "N5", level_source: "jlpt")
    saved_word = SavedWord.create!(user: @user, surface: "食べる", level: "N5",
                                   level_source: "jlpt", jlpt_entry: entry)

    assert_no_enqueued_jobs do
      EstimateSavedWordLevelJob.perform_now(saved_word)
    end

    assert_equal "N5", saved_word.reload.level
  end
end
