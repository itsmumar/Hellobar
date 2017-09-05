class IntegrationMailer < ApplicationMailer
  layout 'user_mailer'
  default from: 'Hello Bar <support@hellobar.com>'

  def sync_error(user, site, provider_name)
    @provider_name = provider_name
    @site = site
    @user = user

    params = {
      subject: "There was a problem syncing your #{ provider_name } account",
      to: user.email
    }

    mail params
  end
end
