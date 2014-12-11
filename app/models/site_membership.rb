class SiteMembership < ActiveRecord::Base
  belongs_to :user
  belongs_to :site
  acts_as_paranoid

  validates :user_id, :uniqueness => {:scope => :site_id}
  validate :only_one_owner_per_site


  private

  def only_one_owner_per_site
    if site && role == "owner" && !site.owner.nil? && site.owner != user
      self.errors.add(:role, "cannot be owner; one already exists for this site")
    end
  end
end
