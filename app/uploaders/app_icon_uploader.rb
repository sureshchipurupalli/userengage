class AppIconUploader < CarrierWave::Uploader::Base
  include CarrierWave::RMagick
  storage :file

  def filename
    if original_filename && original_filename == @filename
      @filename = "#{secure_token(10)}.#{file.extension}" if original_filename.present?
    else
      @filename
    end
  end

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  version :thumb do
    process :resize_to_limit => [200, 200]
  end

  version :small do
    process :resize_to_limit => [400, 400]
  end

  def extension_white_list
    %w(jpg jpeg gif png)
  end

  protected

  def secure_token(length=16)
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) or model.instance_variable_set(var, SecureRandom.hex(length/2))
  end
end

