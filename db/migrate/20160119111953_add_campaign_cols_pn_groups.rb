class AddCampaignColsPnGroups < ActiveRecord::Migration
  def change
    add_column :push_notification_groups, :name, :string, after: :id
    add_column :push_notification_groups, :description, :string, after: :name
  end
end
