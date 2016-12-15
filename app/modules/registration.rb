require 'securerandom'

module Registration
  def post_activation_setup(user_id)


    user = User.where(id: user_id).first

    if user.present?
      role = Role.where(name:'app').first
      # User.all.where(id: user_id).update_all(role_id: role.id) if role.present?
      email = user.email
      name =  email.slice(0..(email.index('@')-1)).gsub(/[^0-9A-Za-z]/, '')
      org = createOrg(name)

      if org.present?
        createOrgSetting(org.id)


        status = 1


        createOrgUser(org.id, user.id,role.id,status)
        mail_invitations = MailInvitation.where(email: user.email, deleted: false, ref_type: 2).first
        if mail_invitations.present?


        orgeapp = App.where(id:mail_invitations.ref_id).first
        end
        if orgeapp.present?
        #createAppUser(orgeapp.id,user.id,role.id,org.id)
        end
        #createAppUser(org.id,user.id,role.id)
        add_user_to_orgs(user)
        add_user_to_apps(user,org)

    end
    end
    end

  def  post_activation_app(app_id)
    app = App.where(id: app_id).first
    if app.present?
      role = Role.where(name:'app').first

    end

  end


  def add_user_to_orgs(user)
     status = 1
    mail_invitations = MailInvitation.where(email: user.email, deleted: false, ref_type: 1)

    if mail_invitations.present? && mail_invitations.size > 0
      mail_invitations.each do |mail_invitation|
        createOrgUser(mail_invitation.ref_id, user.id, mail_invitation.ref_type,status)
        MailInvitation.destroy(mail_invitation.id)
      end
    end
  end
  def add_user_to_apps(user,org)

    mail_invitations = MailInvitation.where(email: user.email, deleted: false, ref_type: 2).first
    if mail_invitations.present?
     org = App.where(id:mail_invitations.ref_id).first

      role_id = 1
      status = 0

        createAppUser(mail_invitations.ref_id, user.id, role_id,org.organisation_id)
        createOrgUser(org.organisation_id, user.id, role_id,status)
        MailInvitation.destroy(mail_invitations.id)
    end


  end



  def setupOrganisation(org_name, org_description="", user_id, role_id, timezone)
    org = createOrg(org_name, org_description, timezone)
    if org.present?
      createOrgSetting(org.id)
      status = 1
      createOrgUser(org.id, user_id, role_id,status)
    end


  end

  def createOrg(name, description = nil, timezone = nil)
    org = Organisation.new()

    org_exist =  Organisation.where(name: name).first.present?
    if org_exist
      org.name = SecureRandom.uuid
    else
      org.name = name
    end

    org.description = description
    org.clientid = SecureRandom.uuid
    org.timezone = timezone
    org.status = 1
    org.save
    org
  end

  def createOrgSetting(org_id)
    orgSetting = OrganisationSetting.new()
    orgSetting.organisation_id = org_id
    orgSetting.setting = 'PackageID'   # 0 - Basic, 1 - Create Company
    orgSetting.value = '0'
    orgSetting.save
  end

  def createOrgUser(org_id, user_id, role_id,status)
    orgUser = OrganisationUser.new()
    orgUser.organisation_id = org_id
    orgUser.role_id = role_id
    orgUser.user_id = user_id
    orgUser.status = status
    orgUser.save
  end

  def createAppUser(app_id, user_id, role_id,org_id)

    appUser = AppUser.new()
    appUser.app_id = app_id
    appUser.role_id = role_id
    appUser.user_id = user_id
    appUser.organisation_id = org_id
    appUser.status = 1
    appUser.save
  end

  def getOrganisations(user_id = nil)
    orgs = []
    if user_id.nil?
      orgs = Organisation.active.all if user_id.nil?
    else
      orgs = Organisation.joins(:organisation_users).where('organisation_users.user_id='+ user_id.to_s)
    end
    orgs
  end
  def getApps(user_id = nil)
    apps = []
    if user_id.nil?
      apps = App.active.all if user_id.nil?
    else
      apps = App.joins(:app_users).where('app_users.user_id='+ user_id.to_s)
    end
    apps
  end

end