class Filter < ActiveRecord::Base
  scope :active, -> { where(status: '0') }

end