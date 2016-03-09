class SiteMembership < ActiveRecord::Base
  belongs_to :user
  belongs_to :site
  acts_as_paranoid

  validate :user, :site, presence: true
  validates :role, inclusion: { in: %w(owner admin) }
  validate :user_site_uniqueness
  validate :user_site_url_uniqueness
  validate :at_least_one_owner_per_site
  validate :updater_permission

  attr_accessor :updated_by

  def can_destroy?
    if role == "owner" && SiteMembership.where(site_id: site_id, role: role).count == 1
      errors.add :site, "must have at least one owner"
      return false
    end
    true
  end

  private

  def updater_permission
    if updated_by && updated_by.role_for_site(site) == :admin
      self.errors.add(:owner, "can only be set by other owners") if role == "owner"
    end
  end

  # Have to write our own because of acts as paranoid
  def user_site_uniqueness
    if site && user && SiteMembership.where(user_id: user.id, site_id: site.id).where.not(id: id).exists?
      self.errors.add(:user, "already has a membership to #{site.url}")
    end
  end

  # Unique by :site_id was not enough since site urls are not unique
  def user_site_url_uniqueness
    if site && user && user.sites.where(url: site.url).any?
      self.errors.add(:user, "already has a membership to #{site.url}")
    end
  end

  def at_least_one_owner_per_site
    unless self.role == "owner" || SiteMembership.where(site_id: site.id, role: "owner").where.not(id: id).exists?
      self.errors.add :site, "must have at least one owner"
    end
  end
end
