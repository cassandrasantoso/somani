class ApplicationController < ActionController::Base
  prepend_before_action :redirect_to_www
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  include Pundit::Authorization

  after_action :verify_authorized,
               unless: -> { skip_pundit? || action_name.in?(%w[index due]) }
  after_action :verify_policy_scoped,
               if: -> { action_name.in?(%w[index due]) }, unless: :skip_pundit?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :route_not_found

  private

  def redirect_to_www
    return unless request.host == "somani.me"

    redirect_to "https://www.somani.me#{request.fullpath}",
                status: :moved_permanently, allow_other_host: true
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(root_path)
  end

  def skip_pundit?
    devise_controller? || params[:controller] =~ /(^(rails_)?admin)|(^pages$)/
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username])
  end

  def route_not_found
    render file: Rails.public_path.join('404.html'), status: :not_found, layout: false
  end
end
