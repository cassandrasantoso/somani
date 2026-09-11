require "test_helper"

class TouchStreakTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "streak-test@example.com", password: "password123", username: "streaktest")
  end

  test "starts a streak at one on first activity" do
    TouchStreak.call(@user)

    assert_equal 1, @user.reload.current_streak
    assert_equal 1, @user.longest_streak
    assert_equal Date.current, @user.last_activity_date
  end

  test "grows the streak on consecutive days" do
    @user.update!(current_streak: 3, longest_streak: 3, last_activity_date: Date.current - 1)

    TouchStreak.call(@user)

    assert_equal 4, @user.reload.current_streak
    assert_equal 4, @user.longest_streak
  end

  test "resets the streak after a missed day but keeps the record" do
    @user.update!(current_streak: 5, longest_streak: 7, last_activity_date: Date.current - 2)

    TouchStreak.call(@user)

    assert_equal 1, @user.reload.current_streak
    assert_equal 7, @user.longest_streak
  end

  test "is a no-op when already touched today" do
    @user.update!(current_streak: 2, longest_streak: 2, last_activity_date: Date.current)

    TouchStreak.call(@user)

    assert_equal 2, @user.reload.current_streak
  end
end
