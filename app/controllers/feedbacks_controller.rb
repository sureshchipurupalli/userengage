class FeedbacksController < ApplicationController
  include Feedbacks
  include Apps
  before_filter :set_defaults
  include PushNotifications
  include FeedbackReplies

  def index

    organisation_id = @app.organisation_id

    @page =  params[:page] || 1
    @per_page = params[:per_page] || 10

    @feedbacks = get_app_feedbacks(@app_id, @page, @per_page)

    respond_to do |format|
      format.html
      format.js
    end
  end


  def reply
    feedback_id = params[:feedback_id]
    @feedback = get_feedback(feedback_id)
    @feedback_category_name = get_feedback_category_name(@feedback.feedback_category_id)
    respond_to do |format|
      format.html
      format.js
    end
  end

  def details
    feedback_id = params[:feedback_id]
    @feedback = get_feedback(feedback_id)
    @feedback_category_name = get_feedback_category_name(@feedback.feedback_category_id)
    @replies = get_feedback_replies(feedback_id)
    @user_details, @mobile_model_details = get_feedback_app_device_details(feedback_id)
    respond_to do |format|
      format.html
      format.js
    end
  end

  def postreply
    @errors = []
    body = params[:body]
    title = params[:title]
    feedback_id = params[:feedback_id]

    if title.blank?
      @errors << t('errors.messages.title_required')
    end

    if body.blank?
      @errors << t('errors.messages.body_required')
    end

    if @errors.present? && @errors.size > 0
      return
    else
      feedback = Feedback.where(id: feedback_id).first
      user_uniq_key = feedback.user_unique_key
      pn_user = PnUser.where(user_uniq_key: user_uniq_key).first

      @app_setting = AppSetting.where(app_id: @app_id,  key: t('ios_app_key'), platform_id: pn_user.platform_id).first
      @errors = send_notifications_to_devices(user_uniq_key, @app_setting.value, title, body, "", "",
                                               "", "", "", "", "", "",
                                               "", "", "", "", "",
                                               @app.id, 3)
      feedback.status = 2
      feedback.save

      unless @errors.present? && @errors.size > 0
        create_feedback_reply(feedback_id, @app_id, current_user.id,title,
                              body,user_uniq_key,pn_user.reference_id)
        @replies = get_feedback_replies(feedback_id)
      end


    end

    if @errors.present? && @errors.size == 0
      @errors = ""
    end

  end


  private

  def set_defaults
    @app = getApp(params[:app_id])
    return redirect_to root_path if @app.blank?
    @app_id = @app.id
    @app_name = @app.name
    @menu_name = "Feedback"
  end
end