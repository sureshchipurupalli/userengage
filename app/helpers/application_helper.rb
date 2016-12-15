module ApplicationHelper
  include GoogleVisualization
  require 'json'

  def custom_error(code, message)
    {code: code, message: message}
  end

  def generate_uniq_uuid(active_record_object, search_key)

    if active_record_object.is_a? Object
      uuid, count = get_uuid_uniq_count(active_record_object, search_key)
      # Iterate loop until get uniq uuid
      while count > 0
        uuid, count = get_uuid_uniq_count(active_record_object, search_key)
      end

      uuid
    end

  end

  def get_uuid_uniq_count(active_record_object, search_key)
    uuid = generate_uuid
    count = active_record_object.where("#{search_key} = ?", uuid).count
    return uuid, count
  end

  def generate_uuid
    SecureRandom.uuid
  end

  def is_json?(foo)
    begin
      return true unless foo.is_a?(String)
      JSON.parse(foo).all?
    rescue JSON::ParserError
      false
    end
  end

  def upload_file(file_url,public_resource_path)
    file_url_path = nil
    original_file_name = nil

    if file_url.present? and public_resource_path.present?
      original_file_name = file_url.original_filename
      file_url_path = SecureRandom.hex(13)+File.extname(file_url.original_filename)
      File.open(public_resource_path+"/"+file_url_path, "wb") { |f| f.write(file_url.read) }
    end
    return file_url_path,original_file_name
  end

  def get_environment_text(code)


      case code.to_i
        when 1
          return "Sandbox"
        when 2
          return "Production"
      end

  end

  def get_platform_text
    ['Android', 'iOS']
  end

  def get_platform(id)
    case id
      when 1
        'Android'
      when 2
        'iOS'
    end
  end

  def get_platform_ids
    Platform.where(:deleted => false).pluck("id")
  end

  def get_platforms
    Platform.where(:deleted => false)
  end

  def get_platform_id(platform_name)
    Platform.where(:deleted => false, name: platform_name).first.id
  end

  def get_platform_name(platform_id)
    Platform.where(:deleted => false, id: platform_id).first.name
  end

  def get_platform_names(platform_ids)
    platform_names = []
    platform_ids.each do |platform_id|
      platform_names << get_platform_name(platform_id)
    end
    platform_names
  end

  def get_mobile_model_name(model_id)
    mobile_model = MobileModel.where(id: model_id).first
    return mobile_model.model + '-' + mobile_model.os_version
  end

  def get_mobile_model_names(model_ids)
    mobile_names = []
    model_ids.each do |model_id|
      mobile_names << get_mobile_model_name(model_id)
    end
    mobile_names
  end

  def get_environments_ids
    return Environment.where(:deleted => false).pluck("id")
  end

  def get_product_user_roles
    [
      {id: 1, name: "Manage Users"},
      {id: 2, name: "Edit"}
    ]
  end

  def get_single_user_group_filters
    [
        {"key" => "Uniq Key", "value" => "user_uniq_key"},
        {"key" => "User Profile Id", "value" => "reference_id"},
        {"key" => "Device Id", "value" => "device_id"}
    ]
  end

  class CustomPolicy
    attr_accessor :policy, :data

    def initialize(policy, data)
      @policy = policy
      @data = data
    end

    def policy_class
      policy
    end
  end

end
