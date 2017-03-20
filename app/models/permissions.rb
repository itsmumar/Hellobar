class Permissions
  ADMIN = :admin
  OWNER = :owner

  PERMISSION_MAP = {
    ADMIN => {
      billing: false,
      delete_site: false,
      invite_user: false
    }.freeze,
    OWNER => {
      billing: true,
      delete_site: true,
      invite_user: true
    }.freeze
  }.freeze

  def self.view_bills?(user, site)
    permission_for(user, site, :billing)
  end

  def self.delete_site?(user, site)
    permission_for(user, site, :delete_site)
  end

  def self.invite_users?(user, site)
    permission_for(user, site, :invite_user)
  end

  def self.permission_for(user, site, feature)
    PERMISSION_MAP[user.role_for_site(site)].try(:[], feature) || false
  end
end
