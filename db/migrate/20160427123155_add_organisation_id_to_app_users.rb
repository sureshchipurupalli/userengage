class AddOrganisationIdToAppUsers < ActiveRecord::Migration
  def change
    create_table "app_users", force: :cascade do |t|
      t.integer  "app_id",     limit: 4,                 null: false
      t.integer  "user_id",    limit: 4,                 null: false
      t.integer  "organisation_id",  limit: 4,                 null: false
      t.integer  "role_id",    limit: 4,                 null: false
      t.integer  "status",     limit: 4, default: 1
      t.boolean  "deleted",    limit: 1, default: false
      t.datetime "created_at",                           null: false
      t.datetime "updated_at",                           null: false
    end

    add_index "app_users", ["app_id"], name: "index_app_users_on_app_id", using: :btree
    add_index "app_users", ["user_id"], name: "index_app_users_on_user_id", using: :btree
    add_index "app_users", ["organisation_id"], name: "index_app_users_on_organisation_id", using: :btree

  end

end
