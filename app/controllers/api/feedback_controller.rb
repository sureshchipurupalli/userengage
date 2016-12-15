
class Api::FeedbackController < Api::ApiController
  include Feedbacks


  def categories
    @categories = get_feedback_categories(@app.id)
    render 'categories', status: :ok
  end

  def create
    @errors = []
    @messages = []
    @feedback_id = 0
    user_unique_key = params[:user_unique_key]
    pn_user_id = params[:pn_user_id]
    latitude = params[:latitude]
    longitude = params[:longitude]
    content = params[:content]
    feedback_category_id = params[:feedback_category_id]
    reference = params[:reference]
    app_id = @app.id
    @errors, @messages, @feedback_id = create_feedback(feedback_category_id, content, latitude, longitude,
                                                       user_unique_key, pn_user_id, reference, app_id)
    if @errors.present?
      render 'api/push_notifications/error'
      return
    end

    render json: {success: true, messages: @messages, feedback_id: @feedback_id}, status: :ok
  end

  def test
    user_timezone = params[:timezone] || 'America/Los_Angeles'
    strdate = params[:date] || '02/18/2016'
    strtime = params[:time] || DateTime.now.strftime("%H:%M").to_s
    scheduled_datetime = convert_date_time(strdate, strtime,user_timezone)
    render text:  "Now:         " + Time.now.utc.to_s +
                  "</br></br></br> Passed:" +  scheduled_datetime.to_s
  end

  def convert_date_time(strdate, strtime, user_timezone)
    date_to_merge = DateTime.strptime(strdate,'%m/%d/%Y')
    time_to_merge = Time.parse(strtime)
    x = Organisation.where(id: session['selected_org']).first
    if x.present?
      user_timezone = x.timezone
    else
      user_timezone = Time.zone.name
    end

    zone = ActiveSupport::TimeZone.new(user_timezone)
    offset = zone.formatted_offset
    merged_datetime = DateTime.new(date_to_merge.year, date_to_merge.month,
                                   date_to_merge.day, time_to_merge.hour,
                                   time_to_merge.min, time_to_merge.sec,offset)

    merged_datetime
  end


  def browser_timezone
    cookies["browser.timezone"]
  end

end
