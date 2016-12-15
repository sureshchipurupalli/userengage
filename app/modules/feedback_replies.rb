module FeedbackReplies
  def create_feedback_reply(feedback_id, app_id, user_profile_id, title, body, user_unique_key, reference)
    FeedbackReply.new do |feedback_reply|
      feedback_reply.feedback_id = feedback_id
      feedback_reply.app_id = app_id
      feedback_reply.user_profile_id = user_profile_id
      feedback_reply.title = title
      feedback_reply.body = body
      feedback_reply.user_unique_key = user_unique_key
      feedback_reply.reference = reference
      feedback_reply.status = 1
      feedback_reply.save
    end
  end

  def get_feedback_replies(feedback_id)
    feedback_replies = FeedbackReply.where(feedback_id: feedback_id, status: 1, deleted: false)
    feedback_replies
  end

end