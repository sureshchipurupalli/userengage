class App < ActiveRecord::Base

  belongs_to :organisation
  has_many :app_settings
  mount_uploader :app_icon, AppIconUploader

  validates_presence_of :name
  scope :active, -> { where(status: 1, deleted: false) }


  def organisation_name

  end

end