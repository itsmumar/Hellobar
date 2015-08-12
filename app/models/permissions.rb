class Permissions
  ADMIN = :admin
  OWNER = :owner

  PERMISSION_MAP = {
    ADMIN => {
      billing: false
    },
    OWNER => {
      billing: true
    }
  }

  def self.view_bills?(user, site)
    PERMISSION_MAP[user.role_for_site(site)].try(:[], :billing) || false
  end
end
