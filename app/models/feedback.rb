class Feedback < ActiveRecord::Base
  has_many :feedback_category
  has_many :app
end