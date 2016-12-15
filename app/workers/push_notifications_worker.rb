class PushNotificationsWorker
  extend DevicePushNotifications
  @queue = :push_notifications

  class << self
    # Sent Group Notifications to mobile devices Asynchronously.
    def perform(notification_group_id)
      send_group_notifications(notification_group_id)
    end

    def send_group_notifications(notification_group_id)
      group_notifications = PushNotification.where(push_notification_group_id: notification_group_id)
      group = PushNotificationGroup.active.where(id: notification_group_id).first

      # Notification Content
      title = group.title
      body = group.body
      app_id = group.app_id

      # sent simple push notifications to target users
      group_notifications.each do |notification|
        if notification.device_notification_id.present?
          simple_push_notification(app_id, notification.platform_id, notification.id,
                                   notification.device_notification_id, title, body)
        end
      end
    end
  end

end