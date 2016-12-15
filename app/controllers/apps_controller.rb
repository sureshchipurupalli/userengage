require 'securerandom'

class AppsController < ApplicationController
  # before_filter :authenticate_user!
  include Apps

  before_filter :set_special_layout
  skip_before_action :verify_authenticity_token

  def index

  end

  def new
    @app = App.new()
    @platforms = getPlatforms()
  end

  def create
    @errors = []
    org_id = session['selected_org'] if session['selected_org'].present?

    app = App.new()
    app.name = params[:name]
    app.description = params[:description]
    app.organisation_id = session[:selected_org]
    app.app_icon = params[:app_icon]
    if app.validate
      app.save
      # generate API Key
      createAppSettings(app.id, 0, 'api_key', SecureRandom.uuid)

      # generate API specific keys.
      selectedPlatforms = getPlatforms
      if selectedPlatforms.present? && selectedPlatforms.size > 0
        selectedPlatforms.each do |platform|
          key = t('ios_app_key')
          value =  SecureRandom.uuid
          createAppSettings(app.id, platform.id, key, value)
        end
      end

      session[:selected_app] = @selected_app = app.id
      #org_id = session['selected_org'] if session['selected_org'].present?
      @user = current_user
      #email = User.select("email").where( id: @user.id )
      role = Role.where(name:'app').first
      createFirstAppUser(app.id, @user.id,role.id,org_id)


    else
      @errors << createerrors(app.errors)
    end
    respond_to do |format|
      format.js
    end
  end

  def edit
    @app = nil
    @clientkey = nil
    @app_settings = nil

    if params[:id].present?
      # Read the client Key
      if session[:selected_org].present?
        @org = Organisation.where(id: session[:selected_org]).first
        @clientkey = @org.clientid
      else
        @clientkey = nil
      end

      # read app settings, api key and app settings
      @app = App.where(id: params[:id]).first
      @api_key = AppSetting.active.where(app_id: @app.id, key: 'api_key')
      @app_settings = AppSetting.active.where(app_id: @app.id)
      session[:selected_app] = @app.id
    end
    @platforms = getPlatforms()
  end

  def update
    @errors = []
    app = App.where(id: params[:id]).first
    if app.present?
      app.name = params[:name]
      app.description = params[:description]
      app.app_icon = params[:app_icon] if  params[:app_icon].present?

      if app.validate
        app.save
        session[:selected_app] = @selected_app = app.id
      else
        @errors << createerrors(app.errors)
      end
    else
      @errors << custom_error(100, "#{t('errors.messages.app_does_not_exist')}")
    end
    respond_to do |format|
      format.js
    end
  end

  def destroy

  end

  def set_special_layout
    if current_user.nil?
      self.class.layout "public_site"
    else
      self.class.layout "account"
    end
  end

  def push_notification_settings
    @app = nil
    @clientkey = nil
    @app_settings = nil

    if params[:app_id].present?
      # Read the client Key
      if session[:selected_org].present?
        @org = Organisation.where(id: session[:selected_org]).first
        @clientkey = @org.clientid
      else
        @clientkey = nil
      end

      # read app settings, api key and app settings
      @app = App.where(id: params[:app_id]).first
      if @app.present?
        @apikey = AppSetting.active.where(app_id: @app.id, key: 'api_key').first.value
        @app_settings = AppSetting.active.where(app_id: @app.id)
        session[:selected_app] = @app.id
      end
    else
      @app = nil
    end
    @platforms = getPlatforms()
  end

  def save_android_pn_settings
    @errors =[]
    if params[:app_id].present?
      app_id = params[:app_id]
      platform_id =  params[:platform_id]
      key =  t('android_pn_key')
      value = params[:android_push_key]
      errors = createAppSettings(app_id, platform_id, key, value)
      @errors << errors if errors.present?
      key =  t('android_pn_package_name')
      value = params[:package_name]
      errors = createAppSettings(app_id, platform_id, key, value)
      @errors << errors if errors.present?
    end
  end

  def save_ios_pn_settings
    @errors =[]
    if params[:app_id].present?
      app_id = params[:app_id]
      platform_id =  params[:platform_id]

      if params[:ios_certificate].present?
        if File.extname(params[:ios_certificate].original_filename).downcase != '.pem'
          errors = t('errors.messages.invalid_apns_cert_content')
          @errors << errors
        else
          key =  t('ios_pn_certificate')
          file = File.open(params[:ios_certificate].tempfile, "rb")
          value = file.read
          errors = createAppSettings(app_id, platform_id, key, value)
          @errors << errors if errors.present?
        end
      end

      if params[:ios_certificate_key].present?
        key =  t('ios_pn_cert_key')
        value = params[:ios_certificate_key]
        errors = createAppSettings(app_id, platform_id, key, value)
        @errors << errors if errors.present?
      end
    end
  end

  def view_ios_pn_certificate

  end


end
