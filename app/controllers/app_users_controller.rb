require 'securerandom'
class AppUsersController < ApplicationController
  before_filter :set_defaults,only: [:new, :create,:index]
  include AppUsers
  include Apps


  def index
    @page =  params[:page] || 1
    @per_page = params[:per_page] || 10


    app_id = session['selected_app'] if session['selected_app'].present?
    org_id = session['selected_org'] if session['selected_org'].present?
    @user = current_user
    user = current_user.id

    email = params[:email]

    user = User.where(email: email, deleted: false).first



    @app_users = get_app_users(app_id, @page, @per_page)
    @invited_users = get_app_invited_users(app_id, @page, @per_page)
    @mails = MailInvitation.where(:ref_type => 2)
  end


  def new
    app_id = session['selected_app'] if session['selected_app'].present?
    org_id = session['selected_org'] if session['selected_org'].present?
    @user = current_user
    user = current_user.id
    isAppUser = AppUser.where(app_id: app_id,user_id: user,organisation_id: org_id,deleted: false)
    @app_user= AppUser.new
   # authorize @app_user

  end


  def create
    @errors = []

    app_id = session['selected_app'] if session['selected_app'].present?

    org_id = session['selected_org'] if session['selected_org'].present?

    @user = current_user

    email = params[:email]
    user = User.where(email: email, deleted: false).first
    if user.present?

      isOrgnUser = OrganisationUser.where(user_id: user.id, organisation_id: org_id, deleted: false).first
      if isOrgnUser.present?

        @errors << AppGlobals.error(2, t('errors.messages.access_granted'))

      else



        email = params[:email]
        if valid_email(email)

          @errors = assign_user_to_app(email,app_id,org_id)

        else
          @errors << t('errors.messages.invalid_email')
        end
      end
    else
      @errors = assign_user_to_app(email,app_id,org_id)
    end
    if @errors.present?
      return  @errors
    else
      return
    end
  end
  def edit

  end

  def update

  end

  def show

  end

  def destroy
    @errors = []

    id = params[:id]
    app_user = AppUser.where(id: id).first
    app_id = app_user.app_id
    app_users = AppUser.where(app_id: app_id, deleted: false)
    if app_users.size > 1
      app_user.deleted = true
      app_user.save
    else
      @errors << "Atleast one user should be there for managing the App."
    end

  end
  private
  def set_defaults
    @app = getApp(params[:app_id])

    return redirect_to root_path if @app.blank?
    @app_id = @app.id

    @app_name = @app.name


  end





end