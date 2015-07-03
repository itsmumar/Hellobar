class SiteMembership < ActiveRecord::Base
  belongs_to :user
  belongs_to :site
  acts_as_paranoid

  validate :user, :site, presence: true
  validates :role, inclusion: { in: %w(owner admin) }
  validate :user_site_uniqueness
  validate :at_least_one_owner_per_site

  before_destroy do
    if role == "owner" && SiteMembership.where(site_id: site_id, role: role).count == 1
      errors.add :site, "must have at least one owner"
      false
    else
      true
    end
  end

  private

  # Have to write our own because of acts as paranoid
  def user_site_uniqueness
    if site && user && SiteMembership.where(user_id: user.id, site_id: site.id).where.not(id: id).exists?
      self.errors.add(:user, "user already has a membership to #{site.url}")
    end
  end

  def at_least_one_owner_per_site
    unless self.role == "owner" || SiteMembership.where(site_id: site.id, role: "owner").where.not(id: id).exists?
      self.errors.add :site, "must have at least one owner"
    end
  end
end
