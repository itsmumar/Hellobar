class Permissions
  ADMIN = :admin
  OWNER = :owner

  PERMISSION_MAP = {
    ADMIN => {
      billing: false,
      delete_site: false
    },
    OWNER => {
      billing: true,
      delete_site: true
    }
  }

  def self.view_bills?(user, site)
    permission_for(user, site, :billing)
  end

  def self.delete_site?(user, site)
    permission_for(user, site, :delete_site)
  end

  def self.permission_for(user, site, feature)
    PERMISSION_MAP[user.role_for_site(site)].try(:[], feature) || false
  end
end
