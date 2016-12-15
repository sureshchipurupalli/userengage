require 'securerandom'

module Apps
  def createAppSettings(app_id, platform_id, key, value)
    errors = []
    appSetting = AppSetting.where(app_id: app_id, platform_id: platform_id, key: key).first
    if appSetting.nil?
      appSetting = AppSetting.new
    end
    appSetting.app_id = app_id
    appSetting.platform_id = platform_id
    appSetting.key = key
    appSetting.value = value
    appSetting.status = 0
    if appSetting.validate
      appSetting.save
    else
      errors << createerrors(appSetting.errors)
    end
    return errors.present? ? errors : nil
  end

  def getPlatforms()
    Platform.active.all
  end

  def getApp(app_id)
    return App.where(id: app_id).active.first
  end

  def getApps(org_id)
    return App.where(organisation_id: org_id, status: 1, deleted: false)
  end
  def getsApp(org_id,user_profile_id)
     appinfo = AppUser.where(organisation_id: org_id,user_id: user_profile_id,deleted: false).first
     return App.where(id: appinfo.app_id,status: 1,deleted: false)
  end

  def getAppStats(user_profile_id, organisation_id = 0)
    if organisation_id == 0
      org_id = getOrgId(user_profile_id)
    else
      org_id = organisation_id

    end

    org_user = OrganisationUser.where(organisation_id: org_id,
                                      user_id: user_profile_id, deleted: false).first
    org_user_role_id = org_user.role_id

    app_stats = {}

    if org_user_role_id == 1
      app_user = AppUser.where(organisation_id:org_id,user_id:user_profile_id,deleted: false).first
      if app_user.present?
        apps = getsApp(org_id,user_profile_id)
      else
      apps = getApps(org_id)
      end

    else

     apps = getUserApps(org_id, user_profile_id)
    end

    if apps.present? && apps.size > 0
      apps.each do |app|
        app_stats[app.id] = {
            :id => app.id,
            :name => app.name,
            :description => app.description,
            :company_id => app.organisation.id,
            :company_name => app.organisation.name,
            :icon_url => app.app_icon
        }
      end
      app_stats.each do |key, value|
        app_stats[key][:crash_count] = get_app_crash_groups_count(key)
        app_stats[key][:user_count] = get_app_PN_users_count(key)
        app_stats[key][:feedback_count] = get_app_feedbacks_count(key)
      end

      app_stats
    end
    app_stats
  end
  def createFirstAppUser(app_id, user_id, role_id,org_id)
    appUser = AppUser.new()
    appUser.app_id = app_id
    appUser.role_id = role_id
    appUser.user_id = user_id
    appUser.organisation_id = org_id
    appUser.status = 1
    appUser.save
  end

  def getUserApps(org_id, user_profile_id)
    return App.joins("join app_users on app_users.app_id = apps.id and app_users.deleted = false
                      and app_users.user_id = " + user_profile_id.to_s + " and app_users.organisation_id = " + org_id.to_s )
  end

  def getVersions(app_id)
    return  PnUser.all.where(deleted: false, status: 1,
                             app_id: app_id).distinct(:app_version_code).pluck(:app_version_name, :app_version_code)
  end

  def getModels(app_id)
    mobile_model_ids =  PnUser.all.where(deleted: false, status: 1,  app_id: app_id).pluck(:mobile_model_id)
    return  MobileModel.all.where("id in (?)", mobile_model_ids).pluck(:id, :model, :os_version)
  end

  def get_app_feedbacks_count(app_id)
    return Feedback.where(app_id: app_id, status: 1, deleted: 0).size
  end

  # def get_app_feedbacks(app_id)
  #
  # end

  def get_app_crash_groups_count(app_id)
    return CrashGroup.where(app_id: app_id, status: 1).size
  end

  def get_app_crash_groups(app_id)
    return CrashGroup.where(app_id: app_id, status: 1)
  end

  def get_app_PN_users_count(app_id)
    return PnUser.where(app_id: app_id, status: 1, deleted: 0).size
  end

  def get_app_PN_users(app_id)
    return PnUser.where(app_id: app_id, status: 1, deleted: 0)
  end

  def getOrgId(user_profile_id)
    org_user = OrganisationUser.where(user_id: user_profile_id, status: 1, deleted: false).first
    if org_user.present?
      return org_user.organisation_id
    end
  end

end