module Feedbackcategories
  include ApplicationHelper
  include Device
  include Notifications
  include AppGlobals

  require 'json'

  def get_feedback_categories(app_id)
    return FeedbackCategory.all.where(deleted: false, status:1, app_id: app_id)
  end

  def create_feedback_category(name, description, app_id)
    errors = []
    messages = []
    feedback_id = 0

    if name.blank?
      errors << custom_error(202, t('errors.messages.category_name_required'))
    else
      feedback_category = FeedbackCategory.where(name: name).first
      if feedback_category.present?
        errors << custom_error(202, t('errors.messages.category_name_exists'))
      end
    end

    if errors.present?
      return errors, messages, feedback_id
    end

    feedback_category_id = 0
    FeedbackCategory.new do |feedback_category|
      feedback_category.name = name
      feedback_category.description = description
      feedback_category.app_id = app_id
      feedback_category.status = 1
      feedback_category.deleted = false
      feedback_category.save
      feedback_category_id = feedback_category.id
    end

    return errors, messages, feedback_category_id

  end

  def delete_feedback_category(feedback_category_id)
    FeedbackCategory.destroy(feedback_category_id)
  end

end