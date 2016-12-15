class FeedbackCategory < ActiveRecord::Base
  has_one :feedback
end