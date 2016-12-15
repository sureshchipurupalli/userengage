class AddAppIdColumnToFilters < ActiveRecord::Migration
  def change
    add_column :filters, :app_id, :integer, after: :id
    remove_column :filters, :campaign_id
  end
end
