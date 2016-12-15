class OrganisationPolicy < ApplicationPolicy
   attr_reader :current_user, :model
  def initialize(current_user, model)
    @current_user = current_user
    @app_user = model
    fail Pundit::NotAuthorizedError unless user
    super
  end
  def new?
    isAppUser.present?

  end

  def update?
    return true
  end

  def show?
    return true
  end

  def create?
    return true
  end

  def destroy?
    return true
  end

  def view?
    return true
  end

end
