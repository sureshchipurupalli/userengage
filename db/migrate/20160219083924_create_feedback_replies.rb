class CreateFeedbackReplies < ActiveRecord::Migration
  def change
    create_table :feedback_replies do |t|
      t.integer   "feedback_id"
      t.integer   "app_id"
      t.string    "user_profile_id"
      t.string    "title"
      t.string    "body"
      t.string    "user_unique_key"
      t.string    "reference"
      t.integer   "status",                 limit: 4,     default: 1,     null: false
      t.boolean   "deleted",                limit: 1,     default: false
      t.datetime  "created_at",                                           null: false
      t.datetime  "updated_at"
    end
  end
end
