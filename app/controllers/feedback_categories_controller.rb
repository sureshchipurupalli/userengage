class FeedbackCategoriesController < ApplicationController

  include Feedbacks
  include Feedbackcategories
  include Apps
  before_filter :set_defaults


  def index

    organisation_id = @app.organisation_id

    @feedback_categories = get_feedback_categories(@app.id)
    respond_to do |format|
      format.html
      format.js
    end
  end

  def new

    @feedback_category = FeedbackCategory.new
    respond_to do |format|
      format.html
      format.js
    end
  end


  def create
    @messages = []
    @errors = []
    @feedback_category_id = 0
    name = params[:feedback_category]["name"]
    description =  params[:feedback_category]["description"]
    app_id = @app_id
    @errors, @messages, @feedback_category_id = create_feedback_category(name, description, app_id)
    respond_to do |format|
      format.html
      format.js
    end
  end

  def destroy
    delete_feedback_category(params[:id])
    respond_to do |format|
      format.html
      format.js
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