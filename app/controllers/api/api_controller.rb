class Api::ApiController < ActionController::Base
  include ApplicationHelper
  before_filter :authenticate_client_id, :except => "test"


  def authenticate_client_id
    errors = []
    client_id = request.headers['HTTP_CLIENT_ID']
    app_key = request.headers['HTTP_APP_KEY']
    api_key = request.headers['HTTP_API_KEY']

    # Validate API Key
    if api_key.present? && USER_ENGAGE_CONFIG['UE_API_KEY'].to_s == api_key

      # validate clientid
      if client_id.present?
        @org = Organisation.where(clientid: client_id, deleted: false).first

        # validate organisation exists with clientid
        if @org.present?

          # validate api_key
          if api_key.present?
            # validate app exists with app id or not
            @app_setting = AppSetting.where(value: app_key, key: t('ios_app_key'), deleted: false).first

            # validate app exists with api_key
            if @app_setting.present?
              @app = App.where(id: @app_setting.app_id, deleted: 0).first
            else
              errors << custom_error(401, "#{t('errors.messages.invalid_app_key')}")
            end

          else
            # api key not submitted
            errors << custom_error(401, "#{t('errors.messages.unauthorized_access')}")
          end
        else
          errors << custom_error(400, "#{t('errors.messages.invalid_client_id')}")
        end
      else
        errors << custom_error(401, "#{t('errors.messages.unauthorized_access')}")
      end
    else
      errors << custom_error(401, "#{t('errors.messages.invalid_api_key')}")
    end

    if errors.size > 0
      render json: {:success => false, :errors => errors}, status: :unauthorized
      return
    end

    request.format = :json

  end

end