class FailedCrash < ActiveRecord::Base
  serialize :crash_details
  serialize :app_details
  serialize :device_details
end