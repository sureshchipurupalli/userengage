class FeedbackReply < ActiveRecord::Base
  has_many :feedbacks
  has_many :apps
  has_many :users
end