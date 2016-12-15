class PushNotification < ActiveRecord::Base
  belongs_to :push_notification_group
end