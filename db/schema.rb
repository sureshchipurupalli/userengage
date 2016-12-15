# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160427123155) do

  create_table "app_settings", force: :cascade do |t|
    t.integer  "app_id",      limit: 4,                     null: false
    t.string   "key",         limit: 255
    t.text     "value",       limit: 65535
    t.integer  "platform_id", limit: 4
    t.integer  "status",      limit: 4,     default: 1
    t.boolean  "deleted",     limit: 1,     default: false
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
  end

  add_index "app_settings", ["app_id"], name: "index_app_settings_on_app_id", using: :btree
  add_index "app_settings", ["platform_id"], name: "index_app_settings_on_platform_id", using: :btree

  create_table "app_users", force: :cascade do |t|
    t.integer  "app_id",          limit: 4,                 null: false
    t.integer  "user_id",         limit: 4,                 null: false
    t.integer  "organisation_id", limit: 4,                 null: false
    t.integer  "role_id",         limit: 4,                 null: false
    t.integer  "status",          limit: 4, default: 1
    t.boolean  "deleted",         limit: 1, default: false
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
  end

  add_index "app_users", ["app_id"], name: "index_app_users_on_app_id", using: :btree
  add_index "app_users", ["organisation_id"], name: "index_app_users_on_organisation_id", using: :btree
  add_index "app_users", ["user_id"], name: "index_app_users_on_user_id", using: :btree

  create_table "apps", force: :cascade do |t|
    t.string   "name",            limit: 255
    t.string   "short_name",      limit: 10
    t.string   "description",     limit: 255
    t.string   "app_icon",        limit: 255
    t.integer  "organisation_id", limit: 4,                   null: false
    t.integer  "status",          limit: 4,   default: 1
    t.boolean  "deleted",         limit: 1,   default: false
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
  end

  add_index "apps", ["organisation_id"], name: "index_apps_on_org_id", using: :btree

  create_table "crash_data", force: :cascade do |t|
    t.integer "crash_id",       limit: 4,     null: false
    t.string  "stack_trace",    limit: 10240
    t.string  "thread_details", limit: 1024
    t.integer "cause_line",     limit: 4
    t.integer "source_line",    limit: 4
  end

  add_index "crash_data", ["crash_id"], name: "index_crash_data_on_crash_id", using: :btree

  create_table "crash_groups", force: :cascade do |t|
    t.integer  "app_id",            limit: 4,    null: false
    t.integer  "platform_id",       limit: 4,    null: false
    t.string   "exception",         limit: 255
    t.string   "source_line",       limit: 255
    t.string   "additional",        limit: 1024
    t.datetime "first_reported_on"
    t.datetime "last_reported_on"
    t.integer  "total_reports",     limit: 4
    t.integer  "total_users",       limit: 4
    t.string   "app_versions",      limit: 1024
    t.string   "os_versions",       limit: 1024
    t.integer  "status",            limit: 4
  end

  add_index "crash_groups", ["app_id"], name: "index_crash_groups_on_app_id", using: :btree
  add_index "crash_groups", ["exception"], name: "index_crash_groups_on_exception", using: :btree
  add_index "crash_groups", ["platform_id"], name: "index_crash_groups_on_platform_id", using: :btree
  add_index "crash_groups", ["source_line"], name: "index_crash_groups_on_source_line", using: :btree

  create_table "crashes", force: :cascade do |t|
    t.integer  "app_id",          limit: 4,                    null: false
    t.integer  "crash_group_id",  limit: 4
    t.integer  "mobile_model_id", limit: 4,                    null: false
    t.integer  "platform_id",     limit: 4
    t.datetime "crash_time",                                   null: false
    t.datetime "app_start_time",                               null: false
    t.string   "report_id",       limit: 255,                  null: false
    t.string   "device_id",       limit: 255
    t.string   "mac_address",     limit: 255
    t.string   "ip_address",      limit: 255
    t.string   "version_code",    limit: 255
    t.string   "version_name",    limit: 255
    t.string   "os_version",      limit: 255
    t.string   "stack_trace",     limit: 1024
    t.boolean  "deleted",         limit: 1,    default: false
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
  end

  add_index "crashes", ["app_id"], name: "index_crashes_on_app_id", using: :btree
  add_index "crashes", ["crash_group_id"], name: "index_crashes_on_crash_group_id", using: :btree
  add_index "crashes", ["mobile_model_id"], name: "index_crashes_on_mobile_model_id", using: :btree

  create_table "failed_crashes", force: :cascade do |t|
    t.text     "error",          limit: 65535
    t.integer  "app_id",         limit: 4
    t.integer  "platform_id",    limit: 4
    t.text     "crash_details",  limit: 65535
    t.text     "app_details",    limit: 65535
    t.text     "device_details", limit: 65535
    t.integer  "status",         limit: 4
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  create_table "feedback_categories", force: :cascade do |t|
    t.integer  "app_id",      limit: 4
    t.string   "name",        limit: 255
    t.string   "description", limit: 255
    t.integer  "status",      limit: 4
    t.boolean  "deleted",     limit: 1
    t.datetime "created_at"
  end

  create_table "feedback_replies", force: :cascade do |t|
    t.integer  "feedback_id",     limit: 4
    t.integer  "app_id",          limit: 4
    t.string   "user_profile_id", limit: 255
    t.string   "title",           limit: 255
    t.string   "body",            limit: 255
    t.string   "user_unique_key", limit: 255
    t.string   "reference",       limit: 255
    t.integer  "status",          limit: 4,   default: 1,     null: false
    t.boolean  "deleted",         limit: 1,   default: false
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at"
  end

  create_table "feedbacks", force: :cascade do |t|
    t.string   "feedback_category_id", limit: 255
    t.integer  "app_id",               limit: 4
    t.string   "content",              limit: 255
    t.integer  "pn_user_id",           limit: 4
    t.string   "user_unique_key",      limit: 255
    t.string   "reference",            limit: 255
    t.decimal  "latitude",                         precision: 10, scale: 6
    t.decimal  "longitude",                        precision: 10, scale: 6
    t.integer  "status",               limit: 4,                            default: 1
    t.boolean  "deleted",              limit: 1,                            default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "filters", force: :cascade do |t|
    t.integer  "app_id",             limit: 4
    t.string   "filter_name",        limit: 255
    t.string   "filter_description", limit: 255
    t.text     "filter_content",     limit: 65535,                 null: false
    t.integer  "status",             limit: 4,     default: 1,     null: false
    t.boolean  "deleted",            limit: 1,     default: false
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
  end

  create_table "mail_invitations", force: :cascade do |t|
    t.string   "email",      limit: 255
    t.integer  "ref_type",   limit: 2
    t.integer  "ref_id",     limit: 4,               null: false
    t.integer  "deleted",    limit: 1,   default: 0
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  create_table "mobile_models", force: :cascade do |t|
    t.string  "key",          limit: 255,                 null: false
    t.string  "brand",        limit: 255
    t.string  "model",        limit: 255
    t.string  "os_version",   limit: 255
    t.string  "display_info", limit: 255
    t.string  "app_name",     limit: 255
    t.boolean "deleted",      limit: 1,   default: false
  end

  create_table "organisation_settings", force: :cascade do |t|
    t.string "organisation_id", limit: 255, null: false
    t.string "setting",         limit: 255, null: false
    t.string "value",           limit: 255, null: false
  end

  create_table "organisation_users", force: :cascade do |t|
    t.integer  "organisation_id", limit: 4,                 null: false
    t.integer  "user_id",         limit: 4,                 null: false
    t.integer  "role_id",         limit: 4,                 null: false
    t.integer  "status",          limit: 4, default: 1
    t.boolean  "deleted",         limit: 1, default: false
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
  end

  add_index "organisation_users", ["organisation_id", "user_id", "role_id"], name: "primary_org", unique: true, using: :btree
  add_index "organisation_users", ["organisation_id"], name: "index_organisation_users_on_organisation_id", using: :btree
  add_index "organisation_users", ["user_id"], name: "index_org_on_user_id", using: :btree

  create_table "organisations", force: :cascade do |t|
    t.string   "name",         limit: 255,                  null: false
    t.string   "description",  limit: 1000
    t.string   "profile_pic",  limit: 500
    t.string   "clientid",     limit: 255,                  null: false
    t.string   "nick_name",    limit: 255
    t.string   "email",        limit: 255
    t.string   "web",          limit: 255
    t.string   "phone1",       limit: 255
    t.string   "phone2",       limit: 255
    t.string   "street1",      limit: 255
    t.string   "street2",      limit: 255
    t.string   "city",         limit: 255
    t.string   "state",        limit: 255
    t.string   "country_code", limit: 255
    t.string   "code",         limit: 255
    t.string   "timezone",     limit: 255
    t.integer  "status",       limit: 4,    default: 0
    t.boolean  "deleted",      limit: 1,    default: false
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
  end

  add_index "organisations", ["name"], name: "index_organisations_on_name", unique: true, using: :btree

  create_table "platforms", force: :cascade do |t|
    t.string   "name",       limit: 255,                 null: false
    t.boolean  "deleted",    limit: 1,   default: false
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
  end

  create_table "pn_users", force: :cascade do |t|
    t.integer  "app_id",                 limit: 4,                   null: false
    t.integer  "platform_id",            limit: 4,                   null: false
    t.string   "user_uniq_key",          limit: 255
    t.string   "device_notification_id", limit: 255
    t.string   "reference_id",           limit: 255
    t.string   "group_name",             limit: 255
    t.string   "device_id",              limit: 255
    t.integer  "mobile_model_id",        limit: 4,                   null: false
    t.string   "os_version",             limit: 255
    t.string   "app_version_code",       limit: 255
    t.string   "app_version_name",       limit: 255
    t.integer  "status",                 limit: 4,   default: 1
    t.integer  "pn_status",              limit: 4,   default: 1
    t.boolean  "deleted",                limit: 1,   default: false
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
  end

  add_index "pn_users", ["app_id"], name: "index_pn_users_on_app_id", using: :btree
  add_index "pn_users", ["mobile_model_id"], name: "index_pn_users_on_mobile_model_id", using: :btree
  add_index "pn_users", ["platform_id"], name: "index_pn_users_on_platform_id", using: :btree

  create_table "push_notification_groups", force: :cascade do |t|
    t.string   "name",                 limit: 255
    t.string   "description",          limit: 255
    t.integer  "app_id",               limit: 4,                        null: false
    t.integer  "filter_id",            limit: 4
    t.string   "notification_key",     limit: 255
    t.integer  "priority",             limit: 4
    t.string   "title",                limit: 255
    t.string   "body",                 limit: 255
    t.string   "version",              limit: 255
    t.binary   "notification_content", limit: 16777215
    t.datetime "scheduled_at"
    t.integer  "notification_type",    limit: 4
    t.integer  "processed_status",     limit: 4
    t.integer  "status",               limit: 4,        default: 1
    t.boolean  "deleted",              limit: 1,        default: false
    t.datetime "created_at",                                            null: false
    t.datetime "updated_at",                                            null: false
  end

  create_table "push_notifications", force: :cascade do |t|
    t.integer  "push_notification_group_id", limit: 4,     null: false
    t.integer  "platform_id",                limit: 4
    t.string   "to",                         limit: 255
    t.string   "device_notification_id",     limit: 255
    t.integer  "retry_count",                limit: 4
    t.integer  "status",                     limit: 4
    t.string   "response_code",              limit: 255
    t.text     "response_text",              limit: 65535
    t.datetime "created_at"
    t.datetime "sent_at"
  end

  create_table "roles", force: :cascade do |t|
    t.string  "name",        limit: 255, default: "", null: false
    t.string  "description", limit: 255, default: "", null: false
    t.integer "status",      limit: 4,   default: 0,  null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255,  default: "",    null: false
    t.string   "first_name",             limit: 255,  default: "",    null: false
    t.string   "last_name",              limit: 255,  default: "",    null: false
    t.string   "encrypted_password",     limit: 255,  default: "",    null: false
    t.integer  "role_id",                limit: 4,    default: 0,     null: false
    t.boolean  "newsletter",             limit: 1,    default: false
    t.boolean  "first_time_login",       limit: 1,    default: true
    t.string   "profile_pic",            limit: 1000
    t.integer  "status",                 limit: 4,    default: 1
    t.boolean  "deleted",                limit: 1,    default: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,    default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
    t.string   "confirmation_token",     limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",      limit: 255
    t.integer  "failed_attempts",        limit: 4,    default: 0,     null: false
    t.string   "unlock_token",           limit: 255
    t.datetime "locked_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["role_id"], name: "fk_rails_642f17018b", using: :btree

end
