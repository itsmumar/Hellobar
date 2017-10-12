class SiteMembership < ActiveRecord::Base
  belongs_to :user
  belongs_to :site
  acts_as_paranoid

  validates :user, :site, presence: true
  validates :role, inclusion: { in: %w[owner admin] }
  validate :at_least_one_owner_per_site
  validate :updater_permission

  attr_accessor :updated_by

  def can_destroy?
    if role == 'owner' && SiteMembership.where(site_id: site_id, role: role).count == 1
      errors.add :site, 'must have at least one owner'
      return false
    end
    true
  end

  private

  def updater_permission
    return unless updated_by&.role_for_site(site) == :admin

    errors.add(:owner, 'can only be set by other owners') if role == 'owner'
  end

  def at_least_one_owner_per_site
    return if role == 'owner' || SiteMembership.where(site_id: site.id, role: 'owner').where.not(id: id).exists?

    errors.add :site, 'must have at least one owner'
  end
end
