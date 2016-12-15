module OrgUsers
  include AppGlobals
  def assign_user_to_organisation(email, org_id)
    errors = []
    messages = []

    org = Organisation.where(id: org_id, deleted: false).first
    role = Role.where(name:'company').first
    user = User.where(email: email, deleted: false).first

    if user.present?
      isOrgUser = OrganisationUser.where(user_id: user.id, organisation_id: org_id, deleted: false).first
      if isOrgUser.present?
        errors << AppGlobals.error(1, t('errors.messages.user_already_assigned_org'))
      else
        isOrgUser = OrganisationUser.where(user_id: user.id, organisation_id: org_id, deleted: true).first

        if isOrgUser.present?
          isOrgUser.deleted = false
          isOrgUser.save
        else
          organisationUser = OrganisationUser.new do |org_user|
          org_user.organisation_id = org_id
          org_user.user_id = user.id
          org_user.role_id = role.id
          org_user.status = 1
          org_user.save
        end

        Mailer.organisation_user_message(user, org.name).deliver_now

        end
      end
    else
      if valid_email(email)
        is_existed_user = MailInvitation.where(email:email, deleted:false, :ref_type => MailInvitation.statuses[:organisation]).first
        if is_existed_user.present?
          errors << AppGlobals.error(2, t('errors.messages.invitation_already_sent'))
        else
          mail_invitation = MailInvitation.new
          mail_invitation.ref_type = MailInvitation.statuses[:organisation]
          mail_invitation.ref_id = org_id
          mail_invitation.email = email
          mail_invitation.save
          begin
            Mailer.organisation_user_invitation(email, org.name).deliver_now
          rescue Exception => ex
            puts "Mailed sending failed " + ex.to_s
          end

        end
      else
        errors << AppGlobals.error(3, t('errors.messages.invalid_email'))
      end
    end

    if errors.present?
      return errors, messages, nil,nil,nil
    else
      return
    end
    # organisation, organisation_users, mail_invitors = get_org_users(org_id,5,10)
    # return errors, messages, organisation, organisation_users, mail_invitors

  end

  def get_org_users_details(org_id)
    organisation = Organisation.where(id: org_id).first
    organisation_users = OrganisationUser.where("org_id = ? and status = ?",org_id,0)
    mail_invitors = MailInvitation.where("ref_id = ? and deleted = ? and ref_type = ? ", org_id, false, MailInvitation.statuses[:organisation])
    return organisation, organisation_users, mail_invitors
  end

  def get_org_users(org_id, page, per_page)
    org_users = OrganisationUser.joins("inner join users on users.id = organisation_users.user_id").
                    where("organisation_users.deleted = false and organisation_users.status = 1 and organisation_users.organisation_id = " + org_id.to_s).
                    select("users.first_name,users.last_name,users.id,users.email,organisation_users.id,
                            organisation_users.role_id")
    #order
    org_users = org_users.order(id: :desc)

    # paging
    org_users = org_users.page(page).per(per_page)
    org_users
  end

  def get_org_invited_users(org_id, page, per_page)
    invited_users = MailInvitation.where(deleted: false, ref_id: org_id, ref_type: '1')

    #order
    invited_users = invited_users.order(id: :desc)

    # paging
    invited_users = invited_users.page(page).per(per_page)
    invited_users
  end

  def is_org_user?(org_id, user_id)
    org_user = OrganisationUser.where(organisation_id: org_id, user_id: user_id)
    if org_user.present?
      return org_user.role_id
    else
      return nil
    end
  end

  # while creating application user. The user should also be added to organisation as member of organisation
  # instead of owner
  def add_user_to_org(org_id, app_id, user_id)
    app_user =  Application
  end

end

