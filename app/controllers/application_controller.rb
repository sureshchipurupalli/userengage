class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :save_return_url_to_session
  before_action :set_profile
  require 'devise/models/authenticatable'
  include Registration
  include Commons
  include Pundit

  def save_return_url_to_session
    session['user_return_to_url'] = request.fullpath if session['user_return_to_url'].blank?
  end

  def set_profile
    profile = current_user
    @orgs = getOrganisations(current_user.id) if current_user.present?
    if @orgs.present? && @orgs.size > 0 &&  session['selected_org'].nil?
      @selected_org = @orgs[0].id
      session['selected_org'] = @selected_org
    else
      @selected_org =  session['selected_org']
    end

    if params[:app_id].present?
      app = App.where(status: 1, deleted: false,  id: params[:app_id])
      session[:selected_app] = @selected_app = params[:app_id] if app.present?
    else
      session[:selected_app] = @selected_app = nil;
    end

  end

  def valid_date?(date_value)
    begin
      return false if date_value.blank? || parse_date(date_value).blank?
    rescue
      return false
    end
    true
  end

  def parse_date(date_str)
    t = Chronic.parse(date_str)
    t.to_date if t.present?
  end

  def pundit_user
    current_user
  end

end
