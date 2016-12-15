class OrganisationUser < ActiveRecord::Base
  belongs_to :organisation
  # enum role_id: { member: 2, owner: 1 }
  scope :active, -> { where(status: 1, deleted: '0') }
end