class FriendshipPolicy < ApplicationPolicy
  def create? = record.follower == user
  def destroy? = record.follower == user
end
