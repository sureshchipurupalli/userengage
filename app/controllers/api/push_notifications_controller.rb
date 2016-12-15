class Api::PushNotificationsController < Api::ApiController
  include PushNotifications

  def register_user
    push_notification_id = params[:push_notification_token]
    platform_name = params[:platform_name]
    device_details = params[:device_details]
    reference_id = params[:user_profile_id]
    group_name = params[:group_name]
    app_details = params[:app_details]

    @errors, @messages, @user_unique_key = register_user_info(@app.id, @app_setting.value, push_notification_id,
                                                              platform_name, device_details, reference_id,
                                                              group_name, app_details)

    if @errors.present?
      render 'error'
      return
    end

    render 'register_user'

  end

  def send_notifications
    messages = []
    user_uniq_key = params[:user_unique_id]
    title = params[:title]
    body = params[:body]
    sound = params[:sound]
    priority = params[:priority]
    content_available = params[:content_available]
    expiration_time = params[:expiration_time]

    icon = params[:icon]
    badge = params[:badge]
    tag = params[:tag]
    collapse_key = params[:collapse_key]
    color = params[:color]
    click_action = params[:click_action]
    data = params[:data]
    delay_while_idle = params[:delay_while_idle]

    notification_key = params[:notification_key]

    notification_type = 2 # 1 - campaign, 2 - API, 3 - Feedback Response

    @errors =  send_notifications_to_devices(user_uniq_key, @app_setting.value, title, body, sound, priority,
                                             content_available, expiration_time, icon, badge, tag, collapse_key,
                                             color, click_action, data, notification_key, delay_while_idle,
                                             @app.id, notification_type)

    if @errors.present?
      render json: {success: false, errors: @errors}, status: :unprocessable_entity
      return
    end

    render json: {success: true, messages: messages}, status: :ok

  end

  def pause_push_notifications
    messages = []
    user_uniq_key = params[:user_unique_id]
    push_notification_id = params[:push_notification_token]
    status = 0
    @errors = update_push_notification_status(push_notification_id, user_uniq_key, status)
    if @errors.present?
      render 'error'
      return
    end

    render json: {success: true, messages: messages}, status: :ok
  end


  def resume_push_notifications
    messages = []
    user_uniq_key = params[:user_unique_id]
    push_notification_id = params[:push_notification_token]
    status = 1
    @errors = update_push_notification_status(push_notification_id, user_uniq_key, status)
    if @errors.present?
      render 'error'
      return
    end

    render json: {success: true, messages: messages}, status: :ok
  end


end