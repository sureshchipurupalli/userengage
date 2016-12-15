class PnUser < ActiveRecord::Base
  belongs_to :mobile_model
  belongs_to :app
  belongs_to :platform

  scope :active, -> { where(status: 1, deleted: false) }

end