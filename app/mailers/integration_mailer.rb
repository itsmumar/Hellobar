class IntegrationMailer < ApplicationMailer
  layout 'user_mailer'
  default from: 'Hello Bar <support@hellobar.com>'

  def sync_error(user, identity)
    @identity = identity
    @site = identity.site
    @user = user

    params = {
      subject: "There was a problem syncing your #{ identity.provider_name } account",
      to: user.email
    }

    mail params
  end
end
