module Feedbacks
  include ApplicationHelper
  include Device
  include Notifications
  include AppGlobals

  require 'json'

  def get_feedback_categories(app_id)
    return FeedbackCategory.all.where(deleted: false, status:1, app_id: app_id)
  end

  def create_feedback(feedback_category_id, content, latitude, longitude, user_unique_key, pn_user_id, reference,
                      app_id)
    errors = []
    messages = []
    feedback_id = 0

    if feedback_category_id.blank?
      errors << custom_error(201, t('errors.messages.feedback_category_required'))
    else
      unless FeedbackCategory.where(id: feedback_category_id).present?
        errors << custom_error(201, t('errors.messages.invalid_feedback_category'))
      end
    end

    if content.blank?
      errors << custom_error(202, t('errors.messages.content_required'))
    end

    if latitude.blank? || longitude.blank?
      errors << custom_error(203, t('errors.messages.latitude_longitude'))
    end

    if user_unique_key.blank? && pn_user_id.blank?
      errors << custom_error(204, t('errors.messages.user_unique_key_user_id_required'))
    else
      pn_user = PnUser.where("user_uniq_key = ? or reference_id = ?", user_unique_key, pn_user_id).first
      errors << custom_error(204, t('errors.messages.invalid_user_unique_key_user_id')) unless pn_user.present?
    end

    if errors.present?
      return errors, messages, feedback_id
    end

    feedback_id = 0
    Feedback.new do |feedback|
      feedback.feedback_category_id = feedback_category_id
      feedback.content = content
      feedback.latitude = latitude
      feedback.longitude = longitude
      feedback.user_unique_key = user_unique_key
      feedback.pn_user_id = pn_user_id
      feedback.reference = reference
      feedback.app_id = app_id
      feedback.save
      feedback_id = feedback.id
    end

    return errors, messages, feedback_id

  end


  def get_app_feedbacks(app_id, page, per_page)

    feedbacks = Feedback.where("deleted = ? and app_id = ?", false, app_id)

    #order
    feedbacks = feedbacks.order(id: :desc)

    # paging
    feedbacks = feedbacks.page(page).per(per_page)

    feedbacks
  end

  def get_feedback_category(feedback_id)
    feedback_category = FeedbackCategory.where(id: feedback_id).first
  end

  def get_feedback_category_name(feedback_category_id)
    feedback_category = FeedbackCategory.where(id: feedback_category_id).first
    return feedback_category.present? ? feedback_category.name : "---"
  end

  def get_feedback(feedback_id)
    return Feedback.where(id: feedback_id, deleted: false).first
  end

  def get_reply_count(feedback_id)
    return FeedbackReply.where(feedback_id: feedback_id, deleted: false).size
  end

  def get_feedback_app_device_details(feedback_id)
    user_uniq_key = Feedback.where(id: feedback_id, deleted: false).first.user_unique_key
    if user_uniq_key.present?
      user_details = PnUser.where(user_uniq_key: user_uniq_key, deleted: false).first
      mobile_model_details = MobileModel.where(id: user_details.mobile_model_id, deleted: false).first
    end
    return user_details, mobile_model_details

  end

end