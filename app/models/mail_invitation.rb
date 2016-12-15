class MailInvitation < ActiveRecord::Base
  enum status: { organisation: 1, app: 2  }
end