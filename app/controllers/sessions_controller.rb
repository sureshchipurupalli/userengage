class SessionsController < Devise::SessionsController
  # require 'hmac-md5'
  protect_from_forgery

  def new
    self.resource = resource_class.new(sign_in_params)
    respond_with(resource, serialize_options(resource), :layout => 'public_site')
  end

  def create
    super
  end

end