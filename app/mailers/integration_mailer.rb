class IntegrationMailer < ApplicationMailer
  default from: 'Hello Bar <support@hellobar.com>'

  def sync_error(user, identity)
    @identity = identity
    @site = identity.site

    params = {
      subject: "There was a problem syncing your #{ identity.provider_name } account",
      to: user.email
    }

    mail params
  end
end
