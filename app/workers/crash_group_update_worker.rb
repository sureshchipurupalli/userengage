class CrashGroupUpdateWorker
  extend CrashReport
  @queue = :crash_group_update

  def self.perform(crash_group_id)
    return if crash_group_id.blank?

    update_crash_group_data(crash_group_id)

  end

end