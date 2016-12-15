# class Mailer < ActionMailer::Base
#   default from: "from@example.com"
# end

class Mailer < ActionMailer::Base

  default from: "noreply@userengage.com"

  def app_user_message(user_profile, app_name)
    @user_profile = user_profile
    @app_name = app_name
    mail(:to => user_profile.email, :subject => t('mailer.app_user_message.subject', app_name: app_name ) )
  end

  def app_user_invitation(email, app_name)
    @app_name = app_name
    @email = email
    mail(:to => email, :subject => t('mailer.app_user_invitation.subject', app_name: app_name ))
  end

  def organisation_user_message(user_profile, organisation_name)
    @host = default_url_options[:host].to_s
    @user_profile = user_profile
    @org_name = organisation_name
    mail(:to => user_profile.email, :subject => t('mailer.org_user_message.subject', org_name: organisation_name ) )
  end

  def organisation_user_invitation(email, organisation_name)
    @host = default_url_options[:host].to_s
    @org_name = organisation_name
    @email = email
    mail(:to => email, :subject => t('mailer.org_user_invitation.subject', org_name: organisation_name ))
  end

end
