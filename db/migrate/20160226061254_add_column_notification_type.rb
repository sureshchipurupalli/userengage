class AddColumnNotificationType < ActiveRecord::Migration
  def change
    add_column :push_notification_groups, :notification_type, :integer, after: :scheduled_at
  end
end
