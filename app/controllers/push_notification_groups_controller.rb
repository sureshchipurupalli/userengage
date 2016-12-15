class PushNotificationGroupsController < ApplicationController
  include PushNotificationGroups
  include Apps
  include ApplicationHelper
  before_filter :set_defaults

  def index

    organisation_id = @app.organisation_id

    @page =  params[:page] || 1
    @per_page = params[:per_page] || 10

    @push_notification_groups = get_push_notification_groups(@app.id, @page, @per_page)

    respond_to do |format|
      format.html
      format.js
    end

  end

  def edit
    organisation_id = @app.organisation_id
    group_id = params[:id]
    platforms = get_platforms()

    @push_notification_group = PushNotificationGroup.joins(:push_notifications).where(app_id: @app_id, id:group_id).active
    # select required fields
    @push_notification_group =  @push_notification_group.select("push_notification_groups.*, count(*) as total, SUM(push_notifications.status = 1) as sent, SUM(push_notifications.status = 2) as failed, SUM(push_notifications.status = 0) as pending").group("push_notifications.push_notification_group_id").first

    @page =  params[:page] || 1
    @per_page = params[:per_page] || 10
    @group_notifications = get_group_notifications(group_id, platforms, @page,  @per_page)

    respond_to do |format|
      format.html
      format.js
    end
  end


  def destroy
    campaign_id = params[:id]
    push_notification_group = PushNotificationGroup.where(id: campaign_id).first
    push_notification_group.deleted = 1
    push_notification_group.save

    @page =  params[:page] || 1
    @per_page = params[:per_page] || 10
    @push_notification_groups = get_push_notification_groups(@app.id, @page, @per_page)

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