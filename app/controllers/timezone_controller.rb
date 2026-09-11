class TimezoneController < ApplicationController
  skip_after_action :verify_authorized

  def create
    zone = ActiveSupport::TimeZone[params[:time_zone].to_s]

    current_user.update!(time_zone: zone.name) if zone && user_signed_in? && current_user.time_zone == "UTC"

    head :no_content
  end
end
