class PushNotificationUsersController < ApplicationController
  include PushNotificationUsers
  include Apps
  before_filter :set_defaults

  def index

    @page =  params[:page] || 1
    @per_page = params[:per_page] || 10

    @push_notification_users = get_push_notification_users(@app_id,'','','', @page, @per_page)

    respond_to do |format|
      format.html
      format.js
    end

  end

  private

  def set_defaults
    @app = getApp(params[:app_id])
    return redirect_to root_path if @app.blank?
    @app_id = @app.id
    @app_name = @app.name
    @menu_name = "push_notifications"
  end

end