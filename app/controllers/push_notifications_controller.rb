require 'json'

class PushNotificationsController < ApplicationController
  include PushNotifications
  include Apps
  include AppGlobals
  include PushNotificationUsers
  include PushNotificationGroups
  before_filter :set_defaults

  def index
    organisation_id = @app.organisation_id
    @platforms = get_platforms
    @campaign_items =  getCampaignWizardItems
    @temp_pn_group_id = generate_unique_key

    if session[:campaign].present?
      mode = params[:mode]
      if mode.present? && mode == "new"
        session[:campaign] = nil
      else
        @campaign = session[:campaign]
      end
    else
      @campaign = nil
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  # Wizard Steps to create campaign

  #step 1
  def save_campaign_details
    @errors = []
    name = params[:name]
    description = params[:description]
    @errors, campaign = create_campaign(@app_id, name, description)
    session[:campaign] = campaign

    respond_to do |format|
      format.html
      format.js
    end
  end

  #step 2

  def create_campaign_content

    if session[:campaign].nil?
      return redirect_to push_notifications_path + "?app_id=" + @app_id.to_s
    end
    @campaign_items =  updateWizarditem('1','1')
    if session[:campaign].present?
      @campaign = session[:campaign]
      @campaign = PushNotificationGroup.where(id: @campaign['id']).first
      session[:campaign] = @campaign
    else
      @campaign = nil
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  #step 3

  def save_pn_message
    pn_message = {}

    @errors = []

    if params[:title].blank?
      @errors << t('errors.messages.invalid_title')

    end

    if params[:body].blank?
      @errors << t('errors.messages.invalid_body')
    end

    if params[:body].present? && params[:title].present?
      title = params[:title].strip
      body = params[:body].strip
      unless ( title + body).bytesize <= 2000 # Validate payload size
        @errors << t('errors.messages.invalid_payload_size')
      end
    end

    if @errors.size == 0
      pn_message[:title] = title
      pn_message[:body] = body
      saved_campaign = session[:campaign]

      if saved_campaign.present?
        campaign =  get_campaign(saved_campaign['id'])
        campaign[:title] = title
        campaign[:body] = body
        campaign.save
      else
        return redirect_to push_notifications_path + '?app_id=' + @app_id.to_s if @app.blank?
      end
      updateWizarditem(2, 1)
      # refresh filters
      session[:platform_filters] = session[:model_filters] = session[:version_filters] = nil
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  # step 4

  def select_pn_users(render = true)
    @page =  params[:page] || 1
    @per_page = params[:per_page] || 10

    if !session[:campaign].nil?

      if session[:platform_filters].nil?
        platform_filters = []
        # build_platform_filters
        session[:platform_filters] = platform_filters
      else
        platform_filters = session[:platform_filters]
      end

      if session[:model_filters].nil?
        model_filters = []
        # build_model_filters(@app_id)
        session[:model_filters] = model_filters
      else
        model_filters = session[:model_filters]
      end

      if session[:version_filters].nil?
        version_filters = []
        # build_version_filters(@app_id)
        session[:version_filters] = version_filters
      else
        version_filters = session[:version_filters]
      end

      @push_notification_users = get_push_notification_users(@app_id, platform_filters, model_filters, version_filters, @page, @per_page)
      @platforms = getPlatforms
      @platform_filters = session[:platform_filters]
      @models = getModels(@app_id)
      @model_filters = session[:model_filters]
      @versions = getVersions(@app_id)
      @version_filters = session[:version_filters]
      session[:user_count] = @push_notification_users.size
    else
      return redirect_to push_notifications_path + '?app_id=' + @app_id.to_s
    end
    @campaign_items =  updateWizarditem(2, 1)

    if render
      respond_to do |format|
        format.html
        format.js
      end
    end
  end

  #step 5

  def preview_and_schedule
    @pn_users = []
    @pn_users << params[:pn_users]
    @targetUsers = @pn_users.size
    session[:targetUsers] = @targetUsers

    platform_filters = session[:platform_filters]
    version_filters = session[:version_filters]
    model_filters = session[:model_filters]
    # for displaying text from ids
    @platform_filters = get_platform_names(platform_filters)
    @version_filters = version_filters
    @model_filters = get_mobile_model_names(model_filters)
    @user_count = session[:user_count] || 0
    saved_campaign = session[:campaign]
    @campaign = get_campaign(saved_campaign['id'])
    if @campaign.present?
      filter_content = convert_filters_to_json(platform_filters, version_filters, model_filters)
      filter = save_filter(@campaign.name,@campaign.description,filter_content,@app_id)
      @campaign.filter_id = filter.id
      @campaign.save
    end
    @campaign_items =  updateWizarditem(3, 1)
    respond_to do |format|
      format.html
      format.js
    end
  end

  #step 6

  def save_and_send
    if !session[:campaign].nil?
      saved_campaign = session[:campaign]
      @campaign = get_campaign(saved_campaign['id'])
      if @campaign.present?
        @campaign.processed_status = 1
        scheduled_datetime = convert_date_time(params[:date],params[:time])
        @campaign.scheduled_at = scheduled_datetime
        @campaign.status = 1
        @campaign.save
      end
    else
      return redirect_to push_notifications_path + '?app_id=' + @app_id.to_s
    end
    respond_to do |format|
      format.html
      format.js
    end

  end

  #step 7

  def campaign_success
    @campaign_items = updateWizarditem(4, 1)
  end

  def save_filtered_users
    respond_to do |format|
      format.html
      format.js
    end
  end

  # filters

  def filter_users_by_platform
    platform_id = params[:platform_id]
    platform_selected = params[:platform_selected]

    if platform_id.present? && platform_selected.present?
      platform_id = platform_id.to_i
      platform_selected = Boolean(platform_selected)
    end

    if session[:platform_filters].present?
      platform_filters = session[:platform_filters]
      if platform_filters.present? && platform_filters.size > 0
        platform_included = platform_filters.include? platform_id
        if platform_included && !platform_selected
          platform_filters.delete(platform_id)
        elsif !platform_included && platform_selected
          platform_filters << platform_id
        end
      end
    elsif platform_selected
      platform_filters = []
      platform_filters << platform_id
    end

    session[:platform_filters] = platform_filters
    select_pn_users(false)
    # redirect_to select_users_path + '?app_id=' + @app_id.to_s
    respond_to do |format|
      format.html
      format.js
    end

  end

  def filter_users_by_model
    model_id = params[:model_id]
    model_selected = params[:model_selected]

    if model_id.present? && model_selected.present?
      model_id = model_id.to_i
      model_selected = Boolean(model_selected)
    end

    if session[:model_filters].present?
      model_filters = session[:model_filters]
      if model_filters.present? && model_filters.size > 0
        model_included = model_filters.include? model_id
        if model_included && !model_selected
          model_filters.delete(model_id)
        elsif !model_included && model_selected
          model_filters << model_id
        end
      end
    elsif model_selected
      model_filters = []
      model_filters << model_id
    end

    session[:model_filters] = model_filters
    select_pn_users(false)
    # redirect_to select_users_path + '?app_id=' + @app_id.to_s
    respond_to do |format|
      format.html
      format.js
    end
  end

  def filter_users_by_version
    version_code = params[:version_code]
    version_selected = params[:version_selected]

    if version_code.present? && version_selected.present?
      version_code = version_code.to_s
      version_selected = Boolean(version_selected)
    end

    if session[:version_filters].present?
      version_filters = session[:version_filters]
      if version_filters.present? && version_filters.size > 0
        version_included = version_filters.include? version_code
        if version_included && !version_selected
          version_filters.delete(version_code)
        elsif !version_included && version_code
          version_filters << version_code
        end
      end
    elsif version_selected
      version_filters = []
      version_filters << version_code
    end

    session[:version_filters] = version_filters
    select_pn_users(false)
    # redirect_to select_users_path + '?app_id=' + @app_id.to_s
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

  def convert_date_time(strdate, strtime)
    date_to_merge = DateTime.strptime(strdate,'%m/%d/%Y')
    time_to_merge = Time.parse(strtime)
    zone = getOrganisationTimezone
    offset = zone.formatted_offset
    merged_datetime = DateTime.new(date_to_merge.year, date_to_merge.month,
                                   date_to_merge.day, time_to_merge.hour,
                                   time_to_merge.min, time_to_merge.sec,offset)

    merged_datetime
  end

  def getOrganisationTimezone
    org_timezone = Organisation.where(id: session['selected_org']).first
    if org_timezone.present?
      user_timezone = org_timezone.timezone
    else
      user_timezone = Time.zone.name
    end
    zone = ActiveSupport::TimeZone.new(user_timezone)
    zone
  end

  def build_platform_filters
    platforms_filters = []
    platforms = getPlatforms()
    platforms.each do |platform|
      platforms_filters << platform.id
    end
    platforms_filters
  end

  def build_model_filters(app_id)
    model_filters = []
    models = getModels(app_id)
    models.each do |model|
      model_filters << model[0]
    end
    model_filters
  end

  def build_version_filters(app_id)
    version_filters = []
    versions = getVersions(app_id)
    versions.each do |version|
      version_filters << version[1]
    end
    version_filters
  end

  def convert_filters_to_json(platform_filters, version_filters, model_filters)
    hash = {}
    hash['filter'] = {}
    if platform_filters.blank? && version_filters.blank? && model_filters.blank?
      hash['filter']['select_all'] = true
    else
      hash['filter']['platforms'] = platform_filters
      hash['filter']['models'] = model_filters
      hash['filter']['versions'] = version_filters
    end
    hash.to_json
  end

  def getCampaignWizardItems

    items = [
        ['0','Create Campaign','1',push_notifications_path + "?app_id=" + @app_id.to_s],
        ['1','Campaign Content','0',create_campaign_content_path + '?app_id=' + @app_id.to_s],
        ['2','Create Segnment','0',select_users_path + "?app_id=" + @app_id.to_s],
        ['3','Create Schedule','0',preview_and_schedule_path + "?app_id=" + @app_id.to_s],
        ['4','Complete','0',campaign_success_path + '?app_id=' + @app_id.to_s]
    ]
    session[:campaign_items] = items
    items
  end

  def updateWizarditem(index, value)
    items = getCampaignWizardItems unless session[:campaign_items].present?
    items = session[:campaign_items]
    items.each do |item|
      if item[0].to_i <= index.to_i
        items[index.to_i][2] = 1
      else
        items[index.to_i][2] = 0
      end
    end
    session[:campaign_items] = items
  end
end