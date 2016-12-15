class AppUser < ActiveRecord::Base
  belongs_to :app
  scope :active, -> { where(status: 1, deleted: '0') }
end