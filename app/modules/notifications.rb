module Notifications
  include ApplicationHelper
  require 'uri'
  require 'net/http'
  require 'net/https'
  require 'json'
  require 'socket'
  require 'openssl'
  include Device

  def send_notification(push_notification_id, product_id)
    # Get Device Information
    push_notifications =  PushNotificationData.where("push_notification_id = ?", push_notification_id).select("notification_content")

    push_notifications.each do |pn|
      pn_content = pn.notification_content
      case pn_content.platform_id
        when 1
          # Android Push Notifications
          product_settings = ProductSetting.where("product_id = ? and deleted = ? and product_settings.key = ?", product_id, false, 'ANDROID_PUSH_KEY').first
          if product_settings.present? && pn_content.push_notification_token.present?
            return send_notifications_to_android_devices(push_notification_id, pn_content, product_settings.value)
          end
        when 2
          # iOS Push Notifications
          product_settings = ProductSetting.where("product_id = ? and deleted = ? and product_settings.key = ?", product_id, false, 'IOS_PUSH_KEY').first
          if product_settings.present? && pn_content.push_notification_token.present?
            return send_notifications_to_ios_devices(push_notification_id, pn_content, product_settings.value)
          end
      end
    end

  end

  def send_notifications_to_android_devices(push_notification_id, push_notification_content, server_api_key)

    begin
      res = ActiveSupport::JSON.decode(send_gcm_notification(push_notification_content, server_api_key))
      errors = []
      puts "GCM Success Response : #{res.to_json}"

      if res["failure"] > 0
        #Errors
        update_notification_response_info(push_notification_id, false, 201, res["results"][0]["error"], Time.now)
        errors << custom_error(103, res["results"][0]["error"])
        return errors
      else
        #Success
        update_notification_response_info(push_notification_id, true, 200, "Notification sent successfully.", Time.now)

        # replace the latest registration ids in old registration ids using canonical ids flag
        if res['canonical_ids'] > 0
          latest_push_notification_token = res['results'][0]['registration_id']
          if latest_push_notification_token.present?
            pn_users = PnUser.where("device_notification_id = ? and deleted = ?",push_notification_content.push_notification_token, false)
            pn_users.each do |pn_user|
              pn_user.device_notification_id = latest_push_notification_token
              pn_user.save
            end
          end
        end

      end
    rescue Exception => e
      # Exception
      update_notification_response_info(push_notification_id, false, 202, e.message, Time.now)
      errors = []
      errors << custom_error(104, e.message)
      return errors
      puts "GCM Exception : #{e.message}"
    end

    return errors

  end

  def send_notifications_to_ios_devices(push_notification_id,push_notification_content, apns_cert)

    begin
      res_code = send_apns_notification(push_notification_content, apns_cert)
      res_status_code = res_code.to_s[1].to_i # get status code from apns response https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/CommunicatingWIthAPS.html
      res_status = apns_error_response(res_status_code)
      errors = []
      puts "APNS Response : #{res_code}, #{res_status}, #{res_status_code}"

      if apns_error_response_codes.include? res_status_code
        # Errors
        update_notification_response_info(push_notification_id, false, res_status_code, res_status, Time.now)
        errors << custom_error(105, res_status)
        return errors
      else
        # Success
        update_notification_response_info(push_notification_id, true, 200, "Notification sent successfully.", Time.now)
      end


    rescue Exception => e
      update_notification_response_info(push_notification_id, false, 202, e.message, Time.now)
      errors << custom_error(106, e.message)
      puts "APNS Exception : #{e.message}"
      return errors
    end

    return errors

  end

  def send_apns_notification(push_notification_data, apns_cert)


    apns_message, device_token = message_content_for_apns(push_notification_data)

    # if message.size.to_i > 256
    #
    # end
    # cert = File.read(File.join(Rails.root, 'public/apns', 'apns_msm.pem'))
     cert = apns_cert

    ctx = OpenSSL::SSL::SSLContext.new
    ctx.key = OpenSSL::PKey::RSA.new(cert, '') #set passphrase here(Private Key if any)
    ctx.cert = OpenSSL::X509::Certificate.new(cert)

    sock = TCPSocket.new('gateway.push.apple.com', 2195) #Production gateway
    # sock = TCPSocket.new('gateway.sandbox.push.apple.com', 2195) #development gateway
    ssl = OpenSSL::SSL::SSLSocket.new(sock, ctx)
    ssl.sync = true
    ssl.connect

    apsn_result = ssl.write(apns_message)

    ssl.close
    sock.close

     apns_feedback(device_token, apns_cert)

    apsn_result

  end

  def send_gcm_notification(push_notification_data, server_api_key)

    request_params, request_header = message_content_for_gcm(push_notification_data, server_api_key)

    uri = URI.parse("https://android.googleapis.com/gcm/send")
    https = Net::HTTP.new(uri.host,uri.port)
    https.use_ssl = true
    req = Net::HTTP::Post.new(uri.path,request_header)
    req.body = request_params
    res = https.request(req).body

    res

  end

  def apns_feedback(device_token, cert)
    # 3e71bcaa9c9e1ea5f9f2dd4f28a1621bd272ba5d05cd67f085f5388e6abdac56
    # cert = File.read(File.join(Rails.root, 'public/apns', 'apns_msm.pem'))
    ctx = OpenSSL::SSL::SSLContext.new
    ctx.key = OpenSSL::PKey::RSA.new(cert, '') #set passphrase here, if any
    ctx.cert = OpenSSL::X509::Certificate.new(cert)

    sock = TCPSocket.new('feedback.push.apple.com', 2196) #Production gateway
    # sock = TCPSocket.new('feedback.sandbox.push.apple.com', 2196) #development gateway
    ssl = OpenSSL::SSL::SSLSocket.new(sock, ctx)
    ssl.sync = true
    ssl.connect

    puts "APNS Feedback Start >>>>>>>>>>>>>> :"

    while line = ssl.read(38) # Read 38 bytes from the SSL socket
      feedback = line.unpack('N1n1H140')
      token = feedback[2].strip

      puts "Feedback Device Token #{token}"
      puts "Feedback Time #{feedback[0]}"
      puts "original device token #{device_token}"

    end

    puts "APNS Feedback End >>>>>>>>>>>>>> :"

    ssl.close
    sock.close

  end


  def message_content_for_apns(push_notification_data)
    result = {}
    result['aps'] = {}
    result['aps']['alert'] = {}

    result['aps']['alert']['title'] = push_notification_data.title if push_notification_data.title.present?
    result['aps']['alert']['body'] = push_notification_data.body if push_notification_data.body.present?
    result['aps']['badge'] = push_notification_data.badge.to_i if push_notification_data.badge.present?
    result['aps']['sound'] = push_notification_data.sound if push_notification_data.sound.present?
    result['aps']['priority'] = push_notification_data.priority if push_notification_data.priority.present?


    # Custom Key Values
    if push_notification_data.data
      push_notification_data.data.each do |key,value|
        result["#{key}"] = "#{value}"
      end
    end

    json = result.to_json
    token =  [push_notification_data.push_notification_token.delete(' ')].pack('H*') #something like 2c0cad 01d1465 346786a9 3a07613f2 b03f0b94b6 8dde3993 d9017224 ad068d36
    apns_message = "\0\0 #{token}\0#{json.length.chr}#{json}"

    return apns_message, push_notification_data.push_notification_token

  end




  def message_content_for_gcm(push_notification_data, server_api_key)
    request_params = {}
    devices = []
    devices << push_notification_data.push_notification_token
    request_params['registration_ids'] = devices
    request_params['notification'] = {}

    request_params['notification']['title'] = push_notification_data.title if  push_notification_data.title.present?
    request_params['notification']['body'] = push_notification_data.body if  push_notification_data.body.present?
    request_params['notification']['icon'] = push_notification_data.icon if  push_notification_data.icon.present?
    request_params['notification']['sound'] = "default" if  push_notification_data.sound.present?
    request_params['notification']['tag'] = push_notification_data.tag if  push_notification_data.tag.present?
    request_params['notification']['click_action'] = push_notification_data.click_action if  push_notification_data.click_action.present?
    request_params['notification']['color'] = push_notification_data.color if  push_notification_data.color.present?

    # Custom Key Values  size must below 4kb
    if push_notification_data.data.present?
      request_params['data'] = {}
      push_notification_data.data.each do |key,value|
        request_params['data']["#{key}"] = "#{value}"
      end
    end

    request_params['collapse_key'] = push_notification_data.collapse_key if  push_notification_data.collapse_key.present?
    request_params['priority'] = push_notification_data.priority if  push_notification_data.priority.present?
    request_params['time_to_live'] = push_notification_data.expiration_time if  push_notification_data.expiration_time.present?
    request_params['content_available'] = push_notification_data.content_available == 'true' if  push_notification_data.content_available.present?
    request_params['delay_while_idle'] = push_notification_data.delay_while_idle == 'true' if  push_notification_data.delay_while_idle.present?


    request_params = request_params.to_json

    request_header = {}
    request_header['Content-Type'] = "application/json"
    request_header['Authorization'] = "key="+server_api_key  #AIzaSyD_ZAzHh10G-ZcEAAehiRoPLXQWeL1SquQ

    return request_params, request_header
  end

  def update_notification_response_info(push_notification_id, success, response_code, response_text, sent_at)

    push_notification = PushNotification.where("id = ?",push_notification_id).first

    if push_notification.present?

      retry_count = push_notification.retry_count+1 rescue 1

      push_notification.success = success
      push_notification.response_code = response_code
      push_notification.response_text= response_text
      push_notification.sent_at = sent_at
      push_notification.retry_count = retry_count
      push_notification.save

      # Create Response Object
      notification_res_obj = Device::Notification.new
      notification_res_obj.success = success
      notification_res_obj.response_code = response_code
      notification_res_obj.response_text = response_text
      notification_res_obj.sent_at = sent_at
      notification_res_obj.retry_count = retry_count

      pn_data = PushNotificationData.where("push_notification_id = ?", push_notification_id).first

      if pn_data.present?
        pn_data.notification_response_content = notification_res_obj
        pn_data.save
      end

    end

  end

  def apns_error_response(error_code)
    case error_code
      when 0
        return 'success'
      when 1
        return 'Processing error'
      when 2
        return 'Missing device token'
      when 3
        return 'Missing topic'
      when 4
        return 'Missing payload'
      when 5
        return 'Invalid token size'
      when 6
        return 'Invalid topic size'
      when 7
        return 'Invalid payload size'
      when 8
        return 'Invalid token'
      when 10
        return 'Shutdown'
      when 255
        return 'None (unknown)'
      else
        return 'Unkown APNS Server Response'
    end
  end

  def apns_error_response_codes
    [1,2,3,4,5,6,7,8,10,255]
    # [1,2,3,4,5,6,7,8,10,255] original array
    # 8 when the device app uninstall it throws 8 but sent push notification to the devise so 8 is removed from the error list
  end

end