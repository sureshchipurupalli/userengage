class CrashReportsController < ApplicationController
  include CrashReport
  include Apps
  # include RoleAccess
  # before_filter :authenticate_user!
  before_filter :set_defaults

  def index
    @platforms = user_platforms
    @platform = params[:platform].to_i if params[:platform].present?
    @platform = @platforms.first if @platform.blank?
    @app_id = params[:app_id] if params[:app_id].present?
    @page =  params[:page] || 1
    @per_page = params[:per_page] || 5
    @org_id = App.where(id: @app_id, deleted: false).first.organisation_id
    @crash_groups = get_crash_groups(@app_id, [@platform], @page.to_i, @per_page.to_i)

    respond_to do |format|
      format.html
      format.js
    end
  end

  def crash_reports
    organisation_id = @app.organisation_id
    @crash_group_id = params[:id]
    @platforms = get_platforms


    @page =  params[:page] || 1
    @per_page = params[:per_page] || 5

    @filters = {
      app_versions: params[:app_versions],
      os_versions: params[:os_versions]
    }

    @include_filter_stats = params.delete(:include_filter_stats)

    if @include_filter_stats.present?
      @app_versions, @os_versions = get_crash_report_filter_stats(@crash_group_id)
    end

    @crash_reports = get_crash_reports(@crash_group_id, @filters, @page, @per_page)

    respond_to do |format|
      format.html
      format.js
    end

  end

  def show
    crash_group_id = params[:id]
    @crash_group_id = params[:id]
    @page =  params[:page] || 1
    @per_page = params[:per_page] || 5
    @filters = {
        app_versions: params[:app_versions],
        os_versions: params[:os_versions]
    }

    @platforms = getPlatforms()
    @crash_group, @os_versions, @app_versions, @day_wise_crashes, @recent_crash = get_crash_group(crash_group_id)
    @platform = @crash_group.platform_id
    @crash_reports = get_crash_reports(@crash_group_id, @filters, @page, @per_page)
    respond_to do |format|
      format.html
      format.js
    end
  end

  private

  def user_platforms
    get_platforms
  end

  def set_defaults
    @app = getApp(params[:app_id])
    return redirect_to root_path if @app.blank?
    @app_id = @app.id
    @app_name = @app.name
    @menu_name = "crash_report"
    # @product_user = ProductUser.where(app_id: @app_id, user_profile_id: current_user.profile.id ).active.first
  end

end