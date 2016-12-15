class PushNotificationGroup < ActiveRecord::Base

  has_many :push_notifications
  belongs_to :app
  scope :active, -> { where(status: 1, deleted: false) }

  # notification_type 1: Campaign 2: From API 3: Feedback Response


end