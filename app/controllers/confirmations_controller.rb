class ConfirmationsController < Devise::ConfirmationsController

  private

  def after_confirmation_path_for(resource_name, resource)
    session[:news_letter_user_id] = resource.id
    confirmation_success_url
  end

end