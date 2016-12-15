class Crash < ActiveRecord::Base
  has_one :crash_data
  belongs_to :mobile_model
  belongs_to :crash_group

  scope :active, -> { where(deleted: false) }

end