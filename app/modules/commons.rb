module Commons
  def createerrors(errors)
    formattederrors = []
    errors.messages.each do |field, value|
      formattederrors << field.to_s + ' ' + value.to_sentence.to_s
    end
    formattederrors
  end

  class AppSettings
    def getAppSettingValue(appSetting)
      if appSetting.present? && appSetting.first.present?
        return appSetting.first.value
      else
        return nil
      end
    end
  end

end