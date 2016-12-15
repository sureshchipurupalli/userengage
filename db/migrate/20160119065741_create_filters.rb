class CreateFilters < ActiveRecord::Migration
  def change
    create_table :filters do |t|
      t.integer   "campaign_id"
      t.string    "filter_name"
      t.string    "filter_description"
      t.text      "filter_content",         limit: 65535,                 null: false
      t.integer   "status",                 limit: 4,     default: 1,     null: false
      t.boolean   "deleted",                limit: 1,     default: false
      t.datetime  "created_at",                                           null: false
      t.datetime  "updated_at",                                           null: false
    end
  end
end
