class HomeController < ApplicationController
  before_filter :set_special_layout
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:register_success, :confirmation_success, :register_newsletter]

  include Registration
  include ApplicationHelper
  include Apps

  def index
    @user = current_user

    email = @user.email if @user.present?

    session[:selected_app] = nil
    org_id = 0
    org_id = session['selected_org'] if session['selected_org'].present?


    @apps_stats = getAppStats(current_user.id, org_id)
    @apps_stats
  end

  def logout
    sign_out @user
    new_user_session_url
  end

  def register_success

  end

  def

  def confirmation_success

  end

  def register_newsletter
    user_id = session[:news_letter_user_id]
    User.where(id: user_id).update_all(newsletter: true)  if user_id.present?
  end

  def change_password
    @user = User.new
  end

  def update_password
    @errors = []
    current_password = params[:user][:password]
    new_password = params[:user][:new_password]
    confirm_password = params[:user][:password_confirmation]

    if current_password.blank?
      @errors << "#{t('errors.messages.existing_password_blank')}"
    end

    if new_password.blank?
      @errors << "#{t('errors.messages.new_password_blank')}"
    end

    if confirm_password.blank?
      @errors << "#{t('errors.messages.confim_password_blank')}"
    end

    if new_password != confirm_password
      @errors << "#{t('errors.messages.new_confirm_password_mismatch')}"
    end

    @user = User.find_by_id(current_user.id)
    if @user.valid_password?(current_password) && @errors.size == 0
      @user.password =  params[:user]["new_password"]
      @user.password_confirmation = params[:user]["password_confirmation"]
      @user.save
      sign_in @user
    else
      @errors << "#{t('errors.messages.incorrect_current_password')}"
    end

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

  private

  def user_params
    # NOTE: Using `strong_parameters` gem
    params.require(:user).permit(:password, :password_confirmation)
  end

end