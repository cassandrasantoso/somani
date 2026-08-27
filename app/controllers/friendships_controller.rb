class FriendshipsController < ApplicationController
  def create
    followed = User.find_by(username: params[:username])
    return redirect_to friends_path, alert: "We couldn't find that username." if followed.nil?

    friendship = current_user.active_friendships.new(followed: followed)
    authorize friendship

    if friendship.save
      redirect_to friends_path, notice: "You're now following #{followed.username}'s progress."
    else
      redirect_to friends_path, alert: friendship.errors.full_messages.to_sentence
    end
  end

  def destroy
    friendship = current_user.active_friendships.find(params[:id])
    authorize friendship
    friendship.destroy

    redirect_to friends_path, notice: "Unfollowed."
  end
end
