# A streak counts consecutive days with any real learning action: sending a
# message in an adventure or grading a review card. Idempotent per day —
# calling it twice on the same date is a no-op.
class TouchStreak
  def self.call(user)
    return user if user.nil?

    today = Date.current
    return user if user.last_activity_date == today

    streak = user.last_activity_date == today - 1 ? user.current_streak + 1 : 1

    user.update!(
      current_streak: streak,
      longest_streak: [streak, user.longest_streak].max,
      last_activity_date: today
    )
    user
  end
end
