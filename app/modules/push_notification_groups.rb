module PushNotificationGroups
  # include PushNotifications
  include PushNotificationUsers
  def get_push_notification_groups(app_id, page = 1, per_page = 20)

    app_groups = PushNotificationGroup.where(app_id: app_id, notification_type: 1, deleted: false).active

    # select required fields
    # app_groups = app_groups.select("push_notification_groups.*, count(*) as total, SUM(push_notifications.status = 1) as sent, SUM(push_notifications.status = 2) as failed, SUM(push_notifications.status = 0) as pending").group("push_notifications.push_notification_group_id")

    #order
    app_groups = app_groups.order(created_at: :desc)

    # paging
    app_groups = app_groups.page(page).per(per_page)

    app_groups

  end

  def get_group_notifications(group_id, platforms, page = 1, per_page = 20)

    group_notifications = PushNotification.where(:push_notification_group_id => group_id, :platform_id => platforms)
    #order
    group_notifications = group_notifications.order(created_at: :desc)
    # paging
    group_notifications = group_notifications.page(page).per(per_page)

    group_notifications
  end


  def create_campaign(app_id, name, description)
      errors = []
      if name.blank?
        errors << t('errors.campaigns.messages.name_not_found')
      end

      if errors.present? && errors.size > 0
        return errors, nil
      else
        pn_group = PushNotificationGroup.new do |png|
          png.name = name
          png.description = description
          png.app_id = app_id
          png.notification_type = 1 # 1 - campaign, 2 - API, 3 - Feedback Response
          png.status = 0
          png.save
        end

        return errors, pn_group
      end
  end

  def get_campaign(campaign_id)
    return PushNotificationGroup.where(id: campaign_id).first
  end

  def save_filter(filter_name = '', filter_description = '', filter_content, app_id)
    filter = Filter.new do |f|
      f.app_id = app_id
      f.filter_name = filter_name
      f.filter_description = filter_description
      f.filter_content = filter_content
      f.save
    end
    filter
  end

  def get_campaigns
    pngs = PushNotificationGroup.where("processed_status = ? and deleted = ? and status = ? and scheduled_at <= ?  ", 1, 0, 1, DateTime.now)
    if pngs.present? && pngs.size > 0
      pngs.each do |png|

        if png.filter_id.present?

          # fetch users from filters
          filter = Filter.where(id: png.filter_id).first
          if filter.present?
            campaign_pn_users = fetch_users_from_filters(filter, png.app_id)
            generate_push_notifications(campaign_pn_users, png.id)
            #enqueue the worker here
            Resque.enqueue(PushNotificationsWorker, png.id)
            png.processed_status = 2
            png.save
          end

        end # if condition for push notification group filter existance
      end # Push notification Group
    end #

  end # end of get_campaigns

  def generate_push_notifications(campaign_pn_users, push_notification_group_id)
    # insert push_notifications
    if campaign_pn_users.present? && campaign_pn_users.size > 0
      campaign_pn_users.each do |pn_user|
        # create_push_notification
        PushNotification.new do |pn|
          pn.push_notification_group_id = push_notification_group_id
          pn.platform_id = pn_user.platform_id
          pn.to = pn_user.user_uniq_key
          pn.device_notification_id = pn_user.device_notification_id
          pn.created_at = Time.now
          pn.retry_count = 0
          pn.status = 0
          pn.save
        end
      end # pn users loop
    end # if pn users available for campaign
  end

  def fetch_users_from_filters(filter, app_id)
    hash = filter.filter_content
    filter_obj = JSON.parse(hash)
    select_all = filter_obj["filter"]["select_all"]
    if select_all.present?
      campaign_pn_users = PnUser.where(app_id: app_id, status: 1, deleted: false)
    else
      model_filters = filter_obj["filter"]["models"]
      platform_filters = filter_obj["filter"]["platforms"]
      version_filters = filter_obj["filter"]["versions"]
      campaign_pn_users = get_push_notification_users(app_id, platform_filters, model_filters, version_filters, 0)
    end
    campaign_pn_users
  end

end