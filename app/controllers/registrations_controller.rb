
class RegistrationsController < Devise::RegistrationsController
  before_filter :set_special_layout

  def update
    @user = current_user
    @user.first_name = params[:user][:first_name]
    @user.last_name = params[:user][:last_name]
    @user.email = params[:user][:email]
    @user.profile_pic = params[:user][:profile_pic]
    @user.save
  end


  protected

  def update_resource(resource, params)
    resource.update_without_password(params)
  end

  def after_inactive_sign_up_path_for(resource)
    register_success_url
  end

  def after_confirmation_path_for(resource_name, resource)
    confirmation_success_url
  end

  private

  def set_special_layout
    if current_user.nil?
      self.class.layout "public_site"
    else
      self.class.layout "account"
    end
  end

  def needs_password?(user, params)
    params[:user][:password].present?
  end

end
