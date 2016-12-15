module PushNotifications
  include ApplicationHelper
  include Device
  include Notifications
  include AppGlobals

  require 'json'

  def register_user_info(app_id, api_key, push_notification_id, platform_name, device_details, reference_id, group_name,
                         app_details)
    errors = []
    messages = []


    if push_notification_id.blank?
      errors << custom_error(201, t('errors.messages.invalid_push_notification_id'))
    end

    if platform_name.blank?
      errors << custom_error(202, t('errors.messages.invalid_platform_name'))
    end

    if device_details.blank? || device_details[:device_id].blank? || device_details[:os_version].blank?
      errors << custom_error(203, t('errors.messages.device_details_required'))
    end

    if app_details.blank? || app_details[:version_name].blank? || app_details[:version_code].blank? || app_details[:package_name].blank?
      errors << custom_error(104, t('errors.messages.app_details_required'))
    end

    if errors.present?
      return errors, messages
    end

    device_id = device_details[:device_id]
    platform_id = get_platform_id(platform_name)

    # Get Pn users info
    pn_user = PnUser.where(:deleted => "false", :status => 1,:app_id => app_id, :device_id => device_id).first

    if pn_user.present?
      user_unique_key = pn_user.user_uniq_key
      update_pn_user_info(pn_user, push_notification_id, device_details[:os_version], reference_id, group_name, app_details, platform_id)
    else
      user_unique_key = generate_uuid
      create_pn_user(app_id, device_id, push_notification_id, user_unique_key, device_details, reference_id, group_name, app_details, platform_id)
    end


    return errors, messages, user_unique_key

  end

  def create_pn_user(app_id, device_id, push_notification_id, user_unique_key, device_details, reference_id, group_name, app_details, platform_id)
    pn_user = PnUser.new do |new_user|
      new_user.user_uniq_key = user_unique_key
      new_user.app_id = app_id
      new_user.device_id = device_id
      new_user.device_notification_id = push_notification_id
      new_user.os_version = device_details[:os_version]
      new_user.mobile_model_id = device_model_id(device_details)
      new_user.platform_id = platform_id
      new_user.reference_id = reference_id
      new_user.group_name = group_name
      new_user.app_version_name = app_details[:version_name]
      new_user.app_version_code = app_details[:version_code]
      new_user.status = 1
      new_user.save
    end
  end

  def update_pn_user_info(pn_user, push_notification_id, os_version, reference_id, group_name, app_details, platform_id)
    pn_user.device_notification_id = push_notification_id
    pn_user.os_version = os_version
    pn_user.reference_id = reference_id
    pn_user.platform_id = platform_id
    pn_user.group_name = group_name
    pn_user.app_version_name = app_details[:version_name]
    pn_user.app_version_code = app_details[:version_code]
    pn_user.save
  end

  def create_notification_device_info(user_uniq_key, api_key, title, body, sound, priority, content_available,
                                      expiration_time, icon, badge,tag, collapse_key, color, click_action, data,
                                      notification_key, delay_while_idle)

    errors = []
    messages = []
    response_object = []

    if body.blank?
      errors << custom_error(101, t('api.body_field_blank'))
      response_temp = {}
      response_temp['success'] = false
      response_temp['errors'] = errors
      response_object << response_temp
      return response_object
    end

    badge = badge.to_i if badge.present?
    priority = priority.to_i if priority.present?
    expiration_time = expiration_time.to_i if expiration_time.present?
    content_available = content_available.to_s if content_available.present?
    delay_while_idle = delay_while_idle.to_s if delay_while_idle.present?

    if user_uniq_key

      if user_uniq_key.is_a? String
        res_err = save_notification_device_info(user_uniq_key, api_key, title, body, sound, priority, content_available,
                                                expiration_time, icon, badge,tag, collapse_key, color, click_action,
                                                data, notification_key, delay_while_idle)
        if res_err.present?
          response_temp = {}
          response_temp['success'] = false
          response_temp['errors'] = res_err
          response_object << response_temp
        else
          response_temp = {}
          response_temp['success'] = true
          response_temp['messages'] = []
          response_object << response_temp
        end


      elsif user_uniq_key.is_a? Array
        user_uniq_key.each do |un_key|
          res_err = save_notification_device_info(un_key, api_key, title, body, sound, priority, content_available,
                                                  expiration_time, icon, badge,tag, collapse_key, color, click_action,
                                                  data, notification_key, delay_while_idle)
          if res_err.present?
            response_temp = {}
            response_temp['success'] = false
            response_temp['errors'] = res_err
            response_object << response_temp
          else
            response_temp = {}
            response_temp['success'] = true
            response_temp['messages'] = []
            response_object << response_temp
          end

        end
      end

    else
      errors << custom_error(102, t('errors.messages.invalid_user_unique_id'))
      response_temp = {}
      response_temp['success'] = false
      response_temp['errors'] = errors
      response_object << response_temp
    end


    return response_object

  end

  def save_notification_device_info(user_uniq_key, api_key, title, body, sound, priority, content_available,
                                    expiration_time, icon, badge,tag, collapse_key, color, click_action, data,
                                    notification_key, delay_while_idle)
    errors = []

    # Get User uniq key
    pn_user = PnUser.joins(:app).select("app_id, device_notification_id, platform_id, os_version")
                                        .where("pn_users.deleted = ? and pn_users.status = ? and apps.deleted = ? and apps.status =? and pn_users.user_uniq_key = ?", false, 1, false, 1, user_uniq_key).first

    # Get app key from app settings
    app_setting = AppSetting.where(deleted: false, value: api_key).first

    if pn_user.blank? || app_setting.blank?
      errors << custom_error(102, t('errors.messages.invalid_api_uniq_key'))
      return errors
    elsif pn_user.app_id != app_setting.app_id
      errors << custom_error(103, t('errors.messages.user_not_found'))
      return errors
    end

    push_notification_token = pn_user.device_notification_id
    platform_id = pn_user.platform_id
    os_version = pn_user.os_version

    new_notification = create_notification_object(push_notification_token, os_version, platform_id, title, body, sound,
                                                  priority, content_available, expiration_time, icon, badge, tag,
                                                  collapse_key, color, click_action, data, delay_while_idle)
    new_push_notification = create_push_notification(notification_key, user_uniq_key, priority, os_version, platform_id)
    create_push_notification_data(new_push_notification.id, new_notification, nil)
    n_errors = send_notification(new_push_notification.id, app_setting.app_id)

    if n_errors.present?
      errors = errors+n_errors
    end

    return errors

  end

  def create_notification_object(push_notification_token,os_version, platform_id,title, body, sound, priority, content_available, expiration_time, icon, badge,tag, collapse_key, color, click_action, data, delay_while_idle)
    # Create New Notification object
    notification = Device::Notification.new
    # notification.push_notification_token = push_notification_token
    # notification.os_version = os_version
    # notification.platform_id = platform_id
    notification.title = title
    notification.body = body
    notification.sound = sound
    notification.priority = priority
    notification.content_available = content_available
    notification.expiration_time = expiration_time
    notification.icon = icon
    notification.badge = badge
    notification.tag = tag
    notification.collapse_key = collapse_key
    notification.color = color
    notification.click_action = click_action
    notification.data = data
    notification.delay_while_idle = delay_while_idle

   return notification
  end

  def create_notification_group_content_object(title, body, sound, priority, content_available, expiration_time, icon, badge,tag, collapse_key, color, click_action, data, delay_while_idle)
    # Create New Notification object
    notification = Device::Notification.new
    # notification.push_notification_token = push_notification_token
    # notification.os_version = os_version
    # notification.platform_id = platform_id
    notification.title = title
    notification.body = body
    notification.sound = sound
    notification.priority = priority
    notification.content_available = content_available
    notification.expiration_time = expiration_time
    notification.icon = icon
    notification.badge = badge
    notification.tag = tag
    notification.collapse_key = collapse_key
    notification.color = color
    notification.click_action = click_action
    notification.data = data
    notification.delay_while_idle = delay_while_idle

    return notification
  end

  def create_push_notification(notification_key, user_uniq_key, priority, os_version, platform_id)

    push_notification =  PushNotification.new do |pn|
      pn.notification_key = notification_key
      pn.to = user_uniq_key
      pn.priority = priority
      pn.version = os_version
      pn.retry_count = 0
      pn.platform_id = platform_id
      pn.created_at = Time.now
      pn.save
    end

    push_notification

  end

  def update_push_notification_response(pn_row_id,retry_count, success, response_code, response_text,sent_at)

    errors = []
    push_notification = PushNotification.where(:id => pn_row_id).first

    if push_notification.present?
      push_notification.retry_count = retry_count
      push_notification.success = success
      push_notification.response_code = response_code
      push_notification.response_text = response_text
      push_notification.sent_at = sent_at
    else
      errors << custom_error(101, t('errors.messages.invalid_notification_id'))
    end

    errors

  end

  def create_push_notification_data(push_notification_id, notification_object, notification_response_object)
    push_notification_data =  PushNotificationData.new do |pn_data|
      pn_data.push_notification_id = push_notification_id
      pn_data.notification_content = notification_object
      pn_data.notification_response_content = notification_response_object
      pn_data.save
    end
  end


  def send_notifications_to_devices(user_uniq_key, api_key, title, body, sound, priority, content_available,
                                    expiration_time, icon, badge,tag, collapse_key, color, click_action, data,
                                    notification_key, delay_while_idle, app_id, notification_type = 2)

    errors = []
    messages = []


    if title.blank?
      errors << custom_error(101, t('errors.messages.invalid_title'))
    elsif title.length < 3
      errors << custom_error(101, t('errors.messages.invalid_title'))
    end

    if body.blank?
      errors << custom_error(102, t('errors.messages.invalid_body'))
    elsif body.length < 5
      errors << custom_error(102, t('errors.messages.invalid_body'))
    end

    if user_uniq_key.blank?
      errors << custom_error(103, t('api.messages.invalid_user_unique_id'))
    end

    if errors.present?
      return errors
    end

    unless (title+body).bytesize <= 2000 # Validate payload size
      errors << custom_error(104, t('errors.messages.invalid_payload_size'))
    end

    if errors.present?
      return errors
    end

    title.strip!
    body.strip!
    badge = badge.to_i if badge.present?
    priority = priority.to_i if priority.present?
    expiration_time = expiration_time.to_i if expiration_time.present?
    content_available = content_available.to_s if content_available.present?
    delay_while_idle = delay_while_idle.to_s if delay_while_idle.present?

    # Get User uniq key
    pn_users = PnUser.joins(:app).select("user_uniq_key, app_id, device_notification_id, platform_id, os_version")
                      .where("pn_users.deleted = ? and pn_users.status = ? and apps.deleted = ? and apps.status =? and app_id = ? and pn_users.pn_status = ?",
                             false, 1, false, 1, app_id, 1).where(user_uniq_key: user_uniq_key)
    # Get Product key info from api key (2)
    app_setting = AppSetting.where(deleted: false, value: api_key).first

    if app_setting.blank?
      errors << custom_error(105, t('errors.messages.app_settings_not_found'))
      return errors
    end

    if pn_users.size == 0
      errors << custom_error(105, t('errors.messages.user_not_found'))
      return errors
    elsif pn_users.first.app_id != app_setting.app_id # User found in this app or not.
      errors << custom_error(106, t('errors.messages.user_not_found'))
      return errors
    end

    app_id = app_setting.app_id
    appsettingscount = 0
    # Check Notification Product Setting keys are configured or not.
    if get_platform_name(app_setting.platform_id).downcase  == 'android'
      appsettingscount = AppSetting.where(:app_id => app_id, :deleted => "false", key: t('android_pn_key')).size
    else get_platform_name(app_setting.platform_id).downcase   == 'ios'
      appsettingscount = AppSetting.where(:app_id => app_id, :deleted => "false", key: t('ios_pn_certificate')).size
    end

    if appsettingscount == 0
      errors << custom_error(107, t('errors.messages.invalid_notification_settings'))
      return errors
    end


    begin
      # Create group with selected grouping users
      notification_content_object = create_notification_group_content_object(title, body, sound, priority, content_available, expiration_time, icon, badge, tag, collapse_key, color, click_action, data, delay_while_idle)
      notification_group = PushNotificationGroup.new do |group|
        group.app_id = app_id
        group.notification_key = notification_key
        group.priority = priority || 10
        group.title = title
        group.body = body
        group.version = nil
        group.notification_type = notification_type # 1 - campaign, 2 - API, 3 - Feedback Response
        group.status = 1
        group.processed_status = 0
        group.filter_id = 0
        group.name = title
        group.description = body
        group.notification_content = notification_content_object
        group.scheduled_at = DateTime.now
        group.save
      end

      # Create notification for each user
      pn_users.each do |user|
        PushNotification.new do |notification|
          notification.push_notification_group_id = notification_group.id
          notification.to = user.user_uniq_key
          notification.device_notification_id = user.device_notification_id
          notification.status = 0
          notification.platform_id = user.platform_id
          notification.save
        end
      end
    rescue Exception => e
      errors << custom_error(150, e.message)
      return errors
    end

    # Sent Group Notification Asynchrnously.
    Resque.enqueue(PushNotificationsWorker, notification_group.id)

    return errors
  end


  def update_push_notification_status(push_notification_id,  user_uniq_key, status)

    errors = []
    push_notification_user = PnUser.where('device_notification_id =  ? OR user_uniq_key = ?', push_notification_id,
                                          user_uniq_key).first

    if push_notification_user.present?
      push_notification_user.pn_status = status
      push_notification_user.save
    else
      errors << custom_error(101, t('errors.messages.invalid_notification_id_and_user_unique_id'))
    end

    errors

  end

end