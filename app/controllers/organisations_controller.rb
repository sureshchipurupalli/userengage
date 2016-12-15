class OrganisationsController < ApplicationController
  before_filter :authenticate_user!
  include Registration

  before_filter :set_special_layout

  def index

  end

  def setCurrentOrganisaton
    org_id = params[:organisation_id]

    org = Organisation.where(id: org_id).first
    if org.present?
      @selected_org = org_id if org.present?
      session['selected_org'] = @selected_org
    end
    respond_to do |format|
      format.js
    end
  end

  def new
    @errors = []
    @org = Organisation.new
    @timezones = getTimeZones
    respond_to do |format|
      format.html
      format.js
    end
  end

  def getTimeZones
    timezones = Timezone::Zone.names
  end

  def organisation_params
    params.require(:organisation).permit(:name, :description, :profile_pic, :timezone)
  end

  def create
    @errors = []
    org = Organisation.new(organisation_params)
    role = Role.where(name:'company').first
    timezone = params[:user_timezones]
    org.status = 0
    if org.validate
      org = setupOrganisation(org.name, org.description, current_user.id, role.id, timezone)
    else
      org.errors.messages.each do |field, value|
        @errors << [ field.to_s + ' ' + value.to_sentence.to_s]
      end
    end
    @orgs = getOrganisations(current_user.id)
    @org = org
    session['selected_org'] = @selected_org = org.id
    respond_to do |format|
      format.js
    end
  end

  def edit
    @errors = []
    @org = Organisation.where(id: params[:id]).first
    @timezones = getTimeZones
    @selected_timezone = @org.timezone
    respond_to do |format|
      format.js
      format.html
    end
  end

  def update
    @errors = []
    @org = Organisation.where(id: params[:id]).first
    if @org.present?
      params[:organisation][:timezone] = params[:user_timezones]
      @org.update_attributes(organisation_params)
      if @org.validate
        @org.save
      else
        @errors << createerrors(@org.errors)
      end
    end

    @orgs = getOrganisations(current_user.id)

    respond_to do |format|
      format.js
    end
  end

  private
  def set_special_layout
    if current_user.nil?
      self.class.layout "public_site"
    else
      self.class.layout "account"
    end
  end

end
