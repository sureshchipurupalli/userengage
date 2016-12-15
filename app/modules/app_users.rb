module AppUsers
  include AppGlobals
  def assign_user_to_app(email, app_id,org_id)


    errors = []
    messages = []

    app = App.where(id: app_id, deleted: false).first
    org = Organisation.where(id: org_id, deleted: false).first
    role = Role.where(name:'company').first





    user = User.where(email: email, deleted: false).first

    if user.present?
      isAppUser = AppUser.where(user_id: user.id, app_id: app_id, deleted: false).first
      if isAppUser.present?
        errors << AppGlobals.error(1, t('errors.messages.user_already_assigned_app'))
      else
        isAppUser = AppUser.where(user_id: user.id, app_id: app_id, deleted: true).first

        if isAppUser.present?
          isAppUser.deleted = false
          isAppUser.save
        else
          appUser = AppUser.new do |app_user|
            app_user.app_id = app_id
            app_user.user_id = user.id
            app_user.organisation_id = org_id
            app_user.role_id = 2
            app_user.status = 0
            app_user.save

          end
          orgUser = OrganisationUser.new do |org_user|
            org_user.user_id = user.id
            org_user.organisation_id = org_id
            org_user.role_id = 1
            org_user.status = 1
            org_user.save
          end

          Mailer.app_user_message(user, app.name).deliver_now

        end
      end
    else
      if valid_email(email)
        is_existed_user = MailInvitation.where(email:email, deleted:false, :ref_type => MailInvitation.statuses[:app],ref_id:app_id).first

        if is_existed_user.present?
          errors << AppGlobals.error(2, t('errors.messages.invitation_already_sent'))





        else
          mail_invitation = MailInvitation.new
          mail_invitation.ref_type = MailInvitation.statuses[:app]
          mail_invitation.ref_id = app_id

          mail_invitation.email = email
          mail_invitation.save
          begin
            Mailer.app_user_invitation(email, app.name).deliver_now
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


  end


  def get_app_users_details(app_id)
    app = App.find(app_id)
    app_users = AppUser.where("app_id = ? and status = ?",app_id,0)
    mail_invitors = MailInvitation.where("ref_id = ? and deleted = ? and ref_type = ? ", app_id, false, MailInvitation.statuses[:organisation])
    return app, app_users, mail_invitors
  end



  def get_app_users(app_id, page, per_page)
    app_users = AppUser.joins("inner join users on users.id = app_users.user_id").
        where("app_users.deleted = false and app_users.app_id = " + app_id.to_s).
        select("users.first_name,users.last_name,users.id,users.email,app_users.id,
                          app_users.role_id")
    #order

    app_users = app_users.order(id: :desc)

    # paging
    app_users = app_users.page(page).per(per_page)
    app_users

  end

  def get_app_invited_users(app_id, page, per_page)
    invited_users = MailInvitation.where(deleted: false, ref_id: app_id, ref_type: '2')

    #order
    invited_users = invited_users.order(id: :desc)

    # paging
    invited_users = invited_users.page(page).per(per_page)
    invited_users
  end



end

