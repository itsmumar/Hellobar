class DestroyIdentity
  def initialize(identity, notify_user: false)
    @identity = identity
    @notify_user = notify_user
  end

  def call
    identity.site.owners.each(&method(:email_user)) if notify_user
    identity.destroy
  end

  private

  include Rails.application.routes.url_helpers

  attr_reader :identity, :notify_user

  def email_user(user)
    MailerGateway.send_email(
      'Integration Sync Error',
      user.email,
      integration_name: identity.provider_name,
      link: site_contact_lists_url(identity.site, host: Settings.host)
    )
  end
end
