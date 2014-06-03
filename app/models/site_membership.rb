class SiteMembership < ActiveRecord::Base
  belongs_to :user
  belongs_to :site

  validates :user_id, :uniqueness => {:scope => :site_id}
  validate :only_one_owner_per_site


  private

  def only_one_owner_per_site
    if site && role == "owner" && !site.owner.nil? && site.owner != user
      self.errors.add(:base, "Sites can only have a single owner")
    end
  end
end
