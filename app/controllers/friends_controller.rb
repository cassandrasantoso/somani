class FriendsController < ApplicationController
  skip_after_action :verify_policy_scoped, only: :index

  def index
    @friendships = current_user.active_friendships.includes(followed: :saved_words)
    @followers_count = current_user.followers.count
    @leaderboard = weekly_leaderboard
  end

  private

  # The user and everyone they follow, ranked by words credited in the last
  # 7 days — production counts, the same signal the word tracker uses.
  def weekly_leaderboard
    users = User.where(id: [current_user.id] + current_user.following.ids)
    counts = WordUsage.where(status: "credited", created_at: 7.days.ago..)
                      .joins(adventure: :upload)
                      .where(uploads: { user_id: users.ids })
                      .group("uploads.user_id")
                      .count

    users.sort_by { |user| [-counts.fetch(user.id, 0), user.username] }
         .map { |user| [user, counts.fetch(user.id, 0)] }
  end
end
