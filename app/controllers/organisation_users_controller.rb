require 'securerandom'

class OrganisationUsersController < ApplicationController

  include OrgUsers

  def index

    @page =  params[:page] || 1
    @per_page = params[:per_page] || 10
    org_id = 0
    org_id = session['selected_org'] if session['selected_org'].present?
    @org_users = get_org_users(org_id, @page, @per_page)
    @invited_users = get_org_invited_users(org_id, @page, @per_page)
  end

  def new

  end

  def create
    org_id = session['selected_org'] if session['selected_org'].present?
    @errors = []
    email = params[:email]
    if valid_email(email)
      @errors = assign_user_to_organisation(email,org_id)
    else
      @errors << t('errors.messages.invalid_email')
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
    org_user = OrganisationUser.where(id: id).first
    org_id = org_user.organisation_id
    org_users = OrganisationUser.where(organisation_id: org_id, deleted: false)
    if org_users.size > 1
      org_user.deleted = true
      org_user.save
    else
      @errors << "Atleast one user should be there for managing the organisation."
    end

  end


end
