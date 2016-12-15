class Api::CrashReportController < Api::ApiController
  include CrashReport

  def save
    Resque.enqueue(CrashReportWorker, @app, @app_setting, params)
    render json: {}, :status => :ok
  end

end