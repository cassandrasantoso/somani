class FriendsController < ApplicationController
  skip_after_action :verify_policy_scoped, only: :index

  def index
    @friendships = current_user.active_friendships.includes(followed: :saved_words)
    @followers_count = current_user.followers.count
  end
end
