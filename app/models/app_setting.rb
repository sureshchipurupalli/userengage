class AppSetting < ActiveRecord::Base
  has_one  :platform
  scope :active, -> { where(status: '0') }
  validates_presence_of :key
  validates_presence_of :value
  validates_presence_of :app_id

end