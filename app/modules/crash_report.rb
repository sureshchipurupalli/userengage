require 'chronic'

module CrashReport
  include ApplicationHelper
  include AppGlobals

  def save_crash(app, app_setting, platform_name, params)
    errors = []
    messages = []

    app_id = app['id'] if app.present?

    app_details = params.delete(:app_details)

    if app_details.blank?
      errors << custom_error(101, I18n.t('errors.crash_report.messages.app_details_required'))
      return errors, messages
    end

    app_package_name =  app_details[:package_name].strip if app_details[:package_name].present?
    if app_package_name.blank?
      errors << custom_error(101, I18n.t('errors.crash_report.messages.app_details_required'))
      return errors, messages
    end

    active_app = app

    if active_app.blank?
      errors << custom_error(102, I18n.t('errors.app.messages.app_not_found'))
      return errors, messages
    end

    package_setting_name =  I18n.t('android_pn_package_name')

    # # read app package name and app_id
    # app_setting =  AppSetting.where(app_id: app_id, key: package_setting_name, deleted: false).first
    # active_app_package_name = app_setting.value
    active_app_package_name = ''
    platform_id = get_platform_id(platform_name)

    # if active_app_package_name.present?
    #   update_package_name(app_id, app_package_name, platform_id)
    # else
    #   if active_app_package_name.downcase.strip != app_package_name.downcase
    #     errors << custom_error(104, I18n.t('errors.crash_report.messages.invalid_package_name'))
    #     return errors, messages
    #   end
    # end

    crash_details = params.delete(:crash_details)
    device_details = params.delete(:device_details)

    errors << custom_error(105, I18n.t('errors.crash_report.messages.crash_details_required')) if crash_details.blank?
    errors << custom_error(106, I18n.t('errors.crash_report.messages.app_details_required')) if device_details.blank?

    if errors.present?
      return errors, messages
    end

    begin
      crash = save_crash_report(app_id,  platform_id, crash_details, app_details, device_details)
    rescue => e

      # Save failed crash for review
      failed_crash = FailedCrash.create do |fc|
        fc.error = e.to_s
        fc.app_id = app_id
        fc.platform_id = active_app[2]
        fc.crash_details = crash_details
        fc.app_details = app_details
        fc.device_details = device_details
        fc.status = 0
      end

    end

    return errors, messages, crash
  end

  def save_crash_report(app_id, platform_id, crash_details, app_details, device_details)
    crash = nil
    case platform_id
      when 1
        crash = save_android_crash_report(app_id, crash_details, app_details, device_details)
      when 2
        #ios
    end
    crash
  end

  def save_android_crash_report(app_id, crash_details, app_details, device_details)

    app_crash_time =  parse_date(crash_details[:app_crash_date])
    crash = Crash.new do |c|
      c.app_id = app_id
      c.mobile_model_id = device_model_id(device_details)
      c.platform_id = 1
      c.crash_time = app_crash_time
      c.app_start_time = parse_date(crash_details[:app_start_date])
      c.report_id = crash_details[:exapption_report_id]
      c.mac_address = device_details[:mac]
      c.ip_address = device_details[:ip]
      c.device_id = device_details[:device_id]
      c.version_name = app_details[:version_name]
      c.version_code = app_details[:version_code]
      c.os_version = device_details[:os_version]
      c.deleted = false

      if crash_details.present?
        c.crash_data = CrashData.new
        c.crash_data.stack_trace = crash_details[:stack_trace]
        c.crash_data.thread_details = crash_details[:thread_details]
      end

    end

    stack_trace_lines = crash_details[:stack_trace].lines

    first_line = ''
    caused_by = ''
    caused_at = ''
    caused_at_condensed = ''
    caused_line = 0
    source_line = 0
    stack_trace_lines.each_with_index do |line, i|
      next if line.blank?
      first_line = line if first_line.blank?
      if caused_at.blank? && line =~ /caused by/i
        temp = line.split(':')
        caused_by =  temp[1].strip if temp[1].present?
        caused_line =  i + 1
      end
      if caused_at.blank? && line =~ /#{Regexp.escape('at ' + app_details[:package_name])}/i
        caused_at = line.strip
        caused_at_condensed = limit_crash_source(caused_at)
        source_line = i + 1
      end
    end

    #handle if caused_by and caused_at not present
    if caused_by.blank?
      temp = first_line.split(':')
      caused_by = temp[0]
      caused_line = 1
    end
    if caused_at.blank?
      caused_at_condensed = limit_stack_trace(crash_details[:stack_trace])
      source_line = 1
    end

    crash_group = CrashGroup.where(app_id: app_id, platform_id: 1, exception: caused_by, source_line: caused_at_condensed).first

    is_new_group = false
    if crash_group.blank?
      is_new_group = true
      crash_group = CrashGroup.new do |cg|
        cg.app_id = app_id
        cg.platform_id = 1
        cg.exception = caused_by
        cg.source_line = caused_at_condensed
        cg.additional = caused_at
        cg.first_reported_on = app_crash_time
        cg.last_reported_on = app_crash_time
        cg.total_reports = 1
        cg.total_users = 1
        cg.status = 1
      end

    end

    ActiveRecord::Base.transaction do

      crash.crash_data.cause_line = caused_line
      crash.crash_data.source_line = source_line
      crash.crash_group = crash_group
      crash.save

      if !is_new_group
        user_count = Crash.where(crash_group_id: crash_group.id, device_id: crash.device_id).active.count
        user_count = user_count > 1 ? 0 : 1
        CrashGroup.where(id: crash_group.id).update_all("last_reported_on = '#{app_crash_time.utc.to_s(:db)}', total_reports = total_reports + 1, total_users = total_users + #{user_count}")
      end
    end

    Resque.enqueue(CrashGroupUpdateWorker, crash_group.id)

    crash
  end

  def update_crash_group_data(crash_group_id)

    os_versions = Crash.where(crash_group_id: crash_group_id).active.group(:os_version).pluck(:os_version)
    app_versions = Crash.where(crash_group_id: crash_group_id).active.group(:version_code, :version_name).pluck(:version_code, :version_name)

    CrashGroup.where(id: crash_group_id).update_all(os_versions: os_versions.join(', '), app_versions: app_versions.map {|a| "#{a[0]} ( #{a[1]} )" }.join(', ') )

  end

  def get_crash_report_filter_stats(crash_group_id)

    crash_reports =  Crash.where(:crash_group_id => crash_group_id).active

    app_versions = crash_reports.select('version_code, version_name').group('version_code, version_name').map{ |v| [v.version_code, v.version_name]}

    os_versions = crash_reports.select('os_version').group('os_version').map(&:os_version)

    return app_versions, os_versions
  end

  def get_crash_groups(app_id, platforms, page = 1, per_page = 20)

    apps = App.where(id: app_id, status: 1, deleted: false)
    # apps = apps.where(:platform_id => platforms) if platforms.present?
    app_ids = apps.pluck(:id)

    crash_groups =  CrashGroup.where(:app_id => app_ids)

    #order
    crash_groups = crash_groups.order(last_reported_on: :desc)

    # paging
    crash_groups = crash_groups.page(page).per(per_page)

    crash_groups
  end

  def get_crash_group(crash_group_id)

    crash_group =  CrashGroup.where(id: crash_group_id).first
    os_versions = Crash.where(crash_group_id: crash_group_id).active.group(:os_version).count
    app_versions = Crash.where(crash_group_id: crash_group_id).active.group(:version_code, :version_name).count
    day_wise_crashes = Crash.where('crash_group_id = ? and crash_time > ?', crash_group_id, 6.days.ago.beginning_of_day).active.group('DATE(crash_time)').count

    recent_crash = Crash.joins(:crash_data).select("crash_data.stack_trace, thread_details, cause_line, source_line").
                        where(crash_group_id: crash_group_id).active.order(created_at: :desc).first


    return crash_group, os_versions, app_versions, day_wise_crashes, recent_crash
  end

  def get_crash_reports(crash_group_id, filters = {}, page, per_page)

    crash_reports =  Crash.includes(:mobile_model).where(:crash_group_id => crash_group_id).active

    if filters[:os_versions].present?
      crash_reports = crash_reports.where(:os_version => filters[:os_versions])
    end

    if filters[:app_versions].present?
      app_version_condition = []
      filters[:app_versions].each do |version|
        code, name =  parse_app_version(version)
        app_version_condition << "(version_code = '#{code}' and version_name = '#{name}')"
      end
      crash_reports =  crash_reports.where(app_version_condition.join(' or '))
    end

    #order
    crash_reports = crash_reports.order(crash_time: :desc)

    # paging
    crash_reports = crash_reports.page(page).per(per_page)

    crash_reports
  end


  private

  def parse_app_version(version)
    versions =  version.split('#$%')
    return versions[0], versions[1]
  end

  def update_package_name(app_id, package_name, platform_id)

    AppSetting.new do |app_setting|
      app_setting.app_id = app_id
      app_setting.key = t('android_pn_package_name')
      app_setting.package_name = package_name
      app_setting.platform_id = platform_id
      app_setting.status = 1
      app_setting.save
    end

  end

  def parse_date(date_value)
    date = Chronic.parse(date)
    date = Time.now  if date.blank?
    date
  end

  def limit_crash_source(data)
    return data if data.length < 250
    return data.first(125) + data.last(125)
  end

  def limit_stack_trace(data)
    data = data.gsub(/[^[:print:]]/i, '')
    return data if data.length < 250

    data_length = data.length
    nth_char = (data_length / 250.0).ceil

    position = nth_char
    condensed = ''
    while true
      break if position > data_length
      condensed += data[position]
      position += nth_char
    end

    condensed
  end

end