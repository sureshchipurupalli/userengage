module AppGlobals

  EMAIL_REGEX = /\A[a-zA-Z0-9.!#$%&'\*\+\/=\?\^\_\`\{\|\}\~-]{1,64}@((?:[-a-z0-9]+\.)+[a-z]{2,})\s*\z/i

  def self.error(code, message)
    message
  end

  def valid_email(email)
    if  email.present? && email =~ EMAIL_REGEX
      return true
    else
      return false
    end

  end

  def device_model_id(device_details)
    device_key = device_unique_key(device_details)
    device_id = MobileModel.where(:key => device_key, :deleted => false).pluck(:id).first

    if device_id.blank?
      mobile_modal = MobileModel.new do |modal|
        modal.key =  device_key
        modal.brand = device_details[:brand]
        modal.model = device_details[:model]
        modal.os_version = device_details[:os_version]
        modal.display_info = device_details[:display_info]
        modal.app_name = device_details[:product_name]
        modal.save
      end
      device_id = mobile_modal.id
    end
    device_id
  end

  private

  def device_unique_key(device_details)
    device_details[:product_name] + device_details[:model] + device_details[:os_version]
  end

  def generate_unique_key
    SecureRandom.uuid
  end

  def Boolean(string)
    # downcase(string) == "true"? true: false
    if string.downcase == "true"
      return true
    elsif  string.downcase == "false"
      return false
    else
      return 'Invalid boolean'
    end
  end

end