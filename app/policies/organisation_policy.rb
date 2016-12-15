class OrganisationPolicy < ApplicationPolicy
  def initialize(user, record)
    fail Pundit::NotAuthorizedError unless user
    super
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
