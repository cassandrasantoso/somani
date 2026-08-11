class SettingsController < ApplicationController
  # story 10 — reminder_enabled + reminder_time live on users
  def edit
    @user = current_user
    authorize @user, :update?
  end

  def update
    @user = current_user
    authorize @user
    if @user.update(settings_params)
      redirect_to edit_settings_path, notice: "Reminders updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def settings_params
    params.require(:user).permit(:reminder_enabled, :reminder_time)
  end
end
