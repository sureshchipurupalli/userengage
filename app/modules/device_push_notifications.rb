module DevicePushNotifications
  include ApplicationHelper
  require 'uri'
  require 'net/http'
  require 'net/https'
  require 'json'
  require 'socket'
  require 'openssl'

  def simple_push_notification(app_id, platform_id, push_notification_id, push_notification_token, title, body)
    case platform_id.to_i
      when 1 # Android
        app_setting = AppSetting.where(:app_id => app_id, :deleted => "false", :key => 'ANDROID_PUSH_KEY').first
        send_notification_to_android_device(push_notification_id, push_notification_token, title, body, app_setting.value) if app_setting.present?
      when 2 # iOS
        app_setting = AppSetting.where(:app_id => app_id, :deleted => "false", :key => 'IOS_PUSH_KEY').first
        send_notification_to_ios_device(push_notification_id, push_notification_token, title, body, app_setting.value) if app_setting.present?
    end
  end

  def send_notification_to_android_device(push_notification_id, push_notification_token, title, body, server_api_key)
    begin
      errors = []
      res = ActiveSupport::JSON.decode(get_android_notification_response(push_notification_token, title, body, server_api_key))
      puts "Android Notification Response : #{res.to_json}"

      if res["failure"] > 0 # Error
        update_notification_response_info(push_notification_id, 2, 201, res["results"][0]["error"], Time.now)
      else # Success
        update_notification_response_info(push_notification_id, 1, 200, "Notification sent successfully.", Time.now)

        # Canonical ids are nothing but duplication of push notification ids with respective person.
        # so update latest push notification id in canonical_ids object.
        # replace the latest registration ids in old registration ids using canonical ids flag
        if res['canonical_ids'] > 0
          latest_push_notification_token = res['results'][0]['registration_id']
          if latest_push_notification_token.present?
            pn_users = PnUser.active.where("device_notification_id = ?", push_notification_token)
            pn_users.each do |pn_user|
              pn_user.device_notification_id = latest_push_notification_token
              pn_user.save
            end
          end
        end
      end
    rescue Exception => e # Exception
      update_notification_response_info(push_notification_id, 2, 202, e.message, Time.now)
      puts "Android Notification Exception : #{e.message}"
    end
  end

  def send_notification_to_ios_device(push_notification_id, push_notification_token, title, body, cert)

    begin
      res_status_code = get_ios_notification_response(push_notification_token, title, body, cert)
      #res_status_code = res_code.to_s[1].to_i # get status code from apns response https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/CommunicatingWIthAPS.html
      res_status = apns_error_response(res_status_code)

      puts "iOS Notification Statuses : #{res_status_code}, #{res_status}"

      if apns_error_response_codes.include? res_status_code # Errors
        update_notification_response_info(push_notification_id, 2, res_status_code, res_status, Time.now)
      else # Success
        update_notification_response_info(push_notification_id, 1, 200, "Notification sent successfully.", Time.now)
      end
    rescue Exception => e
      update_notification_response_info(push_notification_id, 2, 202, e.message, Time.now)
      puts "iOS Notification Exception : #{e.message}"
    end

  end

  def get_android_notification_response(push_notification_token, title, body, server_api_key)

    #GCM request Data
    request_params = {}
    devices = []
    devices << push_notification_token
    request_params['registration_ids'] = devices # Accept token as array with limit 1000 for single request to GCM
    request_params['data'] = {}

    request_params['data']['title'] = title
    request_params['data']['text'] = body
    request_params = request_params.to_json

    # GCM Header
    request_header = {}
    request_header['Content-Type'] = "application/json"
    request_header['Authorization'] = "key="+server_api_key # Sample Key => key=AIzaSyD_ZAzHh10G-ZcEAAehiRoPLXQWeL1SquQ
    puts "Server key :#{'key='+server_api_key}"

    uri = URI.parse("https://gcm-http.googleapis.com/gcm/send") #https://android.googleapis.com/gcm/send
    https = Net::HTTP.new(uri.host,uri.port)
    https.use_ssl = true
    https.verify_mode = OpenSSL::SSL::VERIFY_NONE #= OpenSSL::SSL::VERIFY_PEER
    req = Net::HTTP::Post.new(uri.path,request_header)
    req.body = request_params
    res = https.request(req).body
    res

  end

  def get_ios_notification_response(push_notification_token, title, body, cert)

    #iOS Payload
    request = {}
    request['aps'] = {}
    request['aps']['alert'] = {}

    request['aps']['alert']['title'] = title
    request['aps']['alert']['body'] = body
    request['aps']['badge'] = 1
    request['aps']['sound'] = 'default'
    # request['aps']['priority'] = 10

    json = request.to_json
    unless json.bytesize <= 2048 # Validate payload size
      puts "iOS Notification invalid payload size."
      return
    end
    token =  [push_notification_token.delete(' ')].pack('H*') #something like 2c0cad 01d1465 346786a9 3a07613f2 b03f0b94b6 8dde3993 d9017224 ad068d36
    apns_message = "\0\0 #{token}\0#{json.length.chr}#{json}"

    ctx = OpenSSL::SSL::SSLContext.new
    ctx.key = OpenSSL::PKey::RSA.new(cert, '') #set passphrase here(Private Key if any)
    ctx.cert = OpenSSL::X509::Certificate.new(cert)

    sock = TCPSocket.new('gateway.push.apple.com', 2195) #Production gateway
    # sock = TCPSocket.new('gateway.sandbox.push.apple.com', 2195) #development gateway
    ssl = OpenSSL::SSL::SSLSocket.new(sock, ctx)
    ssl.sync = true
    ssl.connect

    ssl.write(apns_message)

    sleep(1.0) # wait few seconds response from apns
    response_status = 0 # default success

    # This executes if any errors from apns only. otherwise object nil.
    read_socket, write_socket = IO.select([ssl], [ssl], [ssl], nil)
    if (read_socket && read_socket[0])
      if error = ssl.read(6)
        command, response_status, index = error.unpack("ccN")
        puts "iOS Notification Error Response command = #{command}, status= #{response_status}"
      end
    end

    ssl.close
    sock.close

    response_status

  end

  def update_notification_response_info(push_notification_id, status, response_code, response_text, sent_at)

    push_notification = PushNotification.where("id = ?",push_notification_id).first
    if push_notification.present?
      retry_count = push_notification.retry_count+1 rescue 1 # Increment for each failure
      push_notification.status = status # 0 => pending, 1 => success, 2 => failed/error
      push_notification.response_code = response_code
      push_notification.response_text= response_text
      push_notification.sent_at = sent_at
      push_notification.retry_count = retry_count
      push_notification.save
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