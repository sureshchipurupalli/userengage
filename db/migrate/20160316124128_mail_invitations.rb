class MailInvitations < ActiveRecord::Migration
  def change

    create_table "mail_invitations", force: :cascade do |t|
      t.string   "email",      limit: 255
      t.integer  "ref_type",   limit: 2
      t.integer  "ref_id",     limit: 4,               null: false
      t.integer  "deleted",    limit: 1,   default: 0
      t.datetime "created_at",                         null: false
      t.datetime "updated_at",                         null: false
    end

  end
end
