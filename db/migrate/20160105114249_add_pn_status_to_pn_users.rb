class AddPnStatusToPnUsers < ActiveRecord::Migration
  def change
    add_column :pn_users, :pn_status, :integer, after: :status, default: 1
  end
end
