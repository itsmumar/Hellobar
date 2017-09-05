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

  attr_reader :identity, :notify_user

  def email_user(user)
    IntegrationMailer.sync_error(user, identity.site, identity.provider_name).deliver_later
  end
end
