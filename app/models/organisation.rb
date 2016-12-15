class Organisation < ActiveRecord::Base

  has_many :organisation_users
  has_many :organisation_settings
  scope :active, -> { where(status: '0') }
  mount_uploader :profile_pic, OrgProfileUploader

  validates_presence_of :name
  validates_uniqueness_of :name


end