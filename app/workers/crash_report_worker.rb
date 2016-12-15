class CrashReportWorker
  extend CrashReport
  @queue = :crash_report

  def self.perform(app, app_setting, params)
    return if params.blank?

    platform_name = params.delete('platform_name')

    errors, messages = save_crash(app, app_setting, platform_name, params.with_indifferent_access)

  end

end