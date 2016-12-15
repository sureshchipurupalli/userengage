class Platform < ActiveRecord::Base
  scope :active, -> { where(deleted: '0') }
  has_many :app_settings
end