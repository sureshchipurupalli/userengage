module PushNotificationUsers
  def get_push_notification_users(app_id, platforms, models, versions, page = 1, per_page)

    pn_users =  PnUser.includes(:mobile_model).where(:app_id => app_id, deleted: false).active

    #filter platforms

    if platforms.present?
      pn_users = pn_users.where("platform_id in (?)",platforms)
    end

    # filter models

    if models.present?
      pn_users = pn_users.where("mobile_model_id in (?)",models)
    end

    # filter versions

    if versions.present?
      pn_users = pn_users.where("app_version_code in (?)",versions)
    end

    #order
    pn_users = pn_users.order(created_at: :desc)

    # paging
    if page != 0
      pn_users = pn_users.page(page).per(per_page)
    end

    pn_users
  end

  def get_pn_users_filter_stats(product_id, platforms)

    product_apps = ProductApp.where(product_id: product_id).active
    product_apps = product_apps.where(:platform_id => platforms) if platforms.present?
    product_app_ids = product_apps.pluck(:id)

    pn_users =  PnUser.where(:product_app_id => product_app_ids).active

    app_versions = pn_users.select('app_version_code, app_version_name').group('app_version_code, app_version_name').map{ |v| [v.app_version_code, v.app_version_name]}

    os_versions = pn_users.select('os_version').group('os_version').map(&:os_version)

    return app_versions, os_versions
  end

  private

  def parse_app_version(version)
    versions =  version.split('#$%')
    return versions[0], versions[1]
  end

end