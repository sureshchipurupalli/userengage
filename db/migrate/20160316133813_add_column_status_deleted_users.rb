class AddColumnStatusDeletedUsers < ActiveRecord::Migration
  def change
    add_column :users, :status, :integer, after: :profile_pic, default: 1
    add_column :users, :deleted, :boolean, after: :status, default: false
  end
end
