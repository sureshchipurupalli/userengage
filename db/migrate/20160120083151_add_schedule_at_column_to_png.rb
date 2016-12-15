class AddScheduleAtColumnToPng < ActiveRecord::Migration
  def change
    add_column :push_notification_groups, :scheduled_at, :datetime, after: :notification_content
    add_column :push_notification_groups, :processed_status, :integer, after: :scheduled_at
    add_column :push_notification_groups, :filter_id, :integer, after: :app_id
  end
end
