class CreateFeedback < ActiveRecord::Migration

  def change

    create_table :feedback_categories do |t|
      t.integer   "app_id"
      t.string    "name"
      t.string    "description"
      t.integer   "status"
      t.boolean   "deleted"
      t.datetime  "created_at"
    end

    create_table  :feedbacks do |t|
      t.string    "feedback_category_id"
      t.integer   "app_id"
      t.string    "content"
      t.integer   "pn_user_id"
      t.string    "user_unique_key"
      t.string    "reference"
      t.decimal   "latitude",                           precision: 10, scale: 6
      t.decimal   "longitude",                          precision: 10, scale: 6
      t.integer   "status",         default: 1
      t.boolean   "deleted",        default: 0
      t.datetime  "created_at"
      t.datetime  "updated_at"
    end
  end
end
